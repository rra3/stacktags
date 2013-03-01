module StackOverflow
  class IPThrottleError < Exception
  end
  class RelatedTags
    require 'rest_client'
    require 'json'
    require 'hashie'
    require 'open-uri'

    DEVKEY = ENV['STACK_DEV_KEY']

    attr_accessor :resource, :skill

    def initialize(target_skill)
      @resource = 'https://api.stackexchange.com/2.1/tags/'
      @skill = target_skill
    end


    def get_skills
      Hashie::Mash.new(get).items.map do |stuff|
         stuff.name
      end
    end

    private

    def get
      begin
        prepare_resource
        JSON::parse(RestClient.get resource, (set_params skill))
      rescue => e
        error = JSON::parse(e.response)
        raise IPThrottleError, (parse_error_message error) if error["error_id"] == 502
        raise message
      end
    end

    def prepare_resource
      skill.strip!
      skill.gsub!(/\s+/,'-') # spaces to dashes
      skill.gsub!(/\//,'%2f') # urlencode fwd slash - URI::encode seems to miss it
      resource.concat( URI::encode(skill) + '/related')
    end

    def parse_error_message(error)
      "Error ID: " + error["error_id"].to_s + " " + error["error_message"]
    end

    def set_params(skill)
      params = Hash.new { |h, k| h[k] = { } }
      params[:params][:site] = 'stackoverflow.com'
      params[:params][:key] =  DEVKEY
      params
    end

  end
end
