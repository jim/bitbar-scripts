require "file_utils"
require "http/client"
require "json"

require "atomic_write"

module Google
  TOKEN_ENDPOINT = "https://www.googleapis.com/oauth2/v4/token"

  class API
    @token : String?

    def fetch(url)
      refresh_auth_token
      headers = HTTP::Headers.new
      headers.add "Authorization", "Bearer #{@token}"
      HTTP::Client.get(url, headers)
    end

    private def refresh_auth_token
      params = {
        client_id:     ENV.fetch("GCAL_CLIENT_ID"),
        client_secret: ENV.fetch("GCAL_CLIENT_SECRET"),
        grant_type:    "refresh_token",
        refresh_token: ENV.fetch("DOCS_REFRESH_TOKEN"),
      }
      token_response = HTTP::Client.post(TOKEN_ENDPOINT + "?" + HTTP::Params.encode(params))

      data = Hash(String, String | Int32).from_json(token_response.body)
      @token = data["access_token"].to_s
    end

    private def fail(response)
      puts response.status
      puts response.body
      raise "error contacting server"
    end

    private def cache_write(key, body)
      FileUtils.mkdir_p("data/docs")

      File.atomic_write("#{key}.json") do |file|
        file << body
      end
    end

    def cache_read(key)
      path = "#{key}.json"
      File.read(path) if File.exists? path
    end
  end
end
