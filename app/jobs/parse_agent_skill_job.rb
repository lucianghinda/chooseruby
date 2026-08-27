# frozen_string_literal: true

class ParseAgentSkillJob < ApplicationJob
  queue_as :default

  MAX_RESPONSE_SIZE = 1.megabyte
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 10
  MAX_REDIRECTS = 3

  def perform(agent_skill_id)
    @agent_skill = AgentSkill.find(agent_skill_id)

    fetch_and_parse_skill
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "ParseAgentSkillJob: AgentSkill #{agent_skill_id} not found: #{e.message}"
  rescue StandardError => e
    mark_as_failed(e.message)
  end

  private

  def fetch_and_parse_skill
    skill_content = fetch_skill_file

    with_tempfile(skill_content) do |tempfile_path|
      parsed_skill = AgentSkillParser.parse(tempfile_path)
      update_agent_skill(parsed_skill)
      mark_as_completed
    end
  rescue URI::InvalidURIError => e
    mark_as_failed("Invalid URL: #{e.message}")
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    mark_as_failed("Request timeout: #{e.message}")
  rescue StandardError => e
    mark_as_failed("Parsing failed: #{e.message}")
  ensure
    clean_up_tempfile
  end

  def fetch_skill_file
    uri = URI.parse(@agent_skill.skill_file_url)

    raise ArgumentError, "Only HTTPS URLs are allowed" unless uri.is_a?(URI::HTTPS)

    check_dns_rebinding(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http.max_retries = 0

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "ChooseRuby/1.0"

    response = http.request(request)

    follow_redirects(uri, response, 0)
  end

  def follow_redirects(original_uri, response, redirect_count)
    return response.body if response.is_a?(Net::HTTPSuccess)

    if response.is_a?(Net::HTTPRedirection) && redirect_count < MAX_REDIRECTS
      location = response["Location"]
      redirect_uri = URI.join(original_uri.to_s, location)
      raise ArgumentError, "Redirects must use HTTPS" unless redirect_uri.is_a?(URI::HTTPS)
      fetch_skill_file_from_uri(redirect_uri)
    else
      raise StandardError, "HTTP #{response.code}: #{response.message}"
    end
  end

  def fetch_skill_file_from_uri(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "ChooseRuby/1.0"

    response = http.request(request)
    raise StandardError, "HTTP #{response.code}: #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def check_dns_rebinding(uri)
    resolved_ips = Resolv.getaddresses(uri.host)

    private_ranges = [
      IPAddr.new("10.0.0.0/8"),
      IPAddr.new("172.16.0.0/12"),
      IPAddr.new("192.168.0.0/16"),
      IPAddr.new("127.0.0.0/8"),
      IPAddr.new("::1/128")
    ]

    resolved_ips.each do |ip|
      ip_addr = IPAddr.new(ip)
      private_ranges.each do |range|
        raise ArgumentError, "DNS rebinding detected: #{uri.host} resolves to private IP #{ip}" if range.include?(ip_addr)
      end
    end
  rescue Resolv::ResolvError => e
    raise StandardError, "DNS resolution failed for #{uri.host}: #{e.message}"
  end

  def with_tempfile(content)
    tempfile = Tempfile.new([ "agent_skill_", ".md" ], binmode: true)
    @tempfile_path = tempfile.path

    tempfile.write(content)
    tempfile.flush
    tempfile.rewind

    yield tempfile.path
  ensure
    tempfile.close
  end

  def update_agent_skill(parsed_skill)
    @agent_skill.update(
      name: parsed_skill.name,
      skill_description: parsed_skill.description,
      license: parsed_skill.license,
      compatibility: parsed_skill.compatibility,
      pattern: parsed_skill.pattern,
      metadata: parsed_skill.metadata || {},
      allowed_tools: serialize_allowed_tools(parsed_skill.allowed_tools),
      body: parsed_skill.body
    )
  end

  def serialize_allowed_tools(allowed_tools)
    return [] if allowed_tools.nil? || allowed_tools.empty?

    allowed_tools.map do |tool|
      if tool.respond_to?(:to_h)
        tool.to_h
      elsif tool.is_a?(Hash)
        tool
      else
        { name: tool.to_s }
      end
    end
  end

  def mark_as_completed
    @agent_skill.update(parse_status: :parse_completed, parse_error: nil)
  end

  def mark_as_failed(error_message)
    @agent_skill.update(parse_status: :parse_failed, parse_error: error_message.truncate(1000))
  end

  def clean_up_tempfile
    File.delete(@tempfile_path) if @tempfile_path && File.exist?(@tempfile_path)
  rescue StandardError => e
    Rails.logger.warn "Failed to cleanup tempfile #{@tempfile_path}: #{e.message}"
  end
end
