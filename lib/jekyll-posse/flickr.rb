require 'rest-client'
require 'openssl'
require 'base64'
require 'flickr'

module JekyllPosse
  class FlickrPosse

    def initialize(data = nil, content = nil, silo = nil, download = false)
      @domain = "https://www.flickr.com/services/rest"
      @data = data
      @content = content
      @url = silo
      @download = download
      @consumer_key = ENV["FLICKR_CONSUMER_KEY"]
      @consumer_secret = ENV["FLICKR_CONSUMER_SECRET"]
      @token = ENV["FLICKR_ACCESS_TOKEN"]
      @token_secret = ENV["FLICKR_TOKEN_SECRET"]

      @client = Flickr.new @consumer_key, @consumer_secret
      @client.access_token = @token
      @client.access_secret = @token_secret
    end

    def notes
    end

    def replies
    end

    def reposts
    end

    def likes
    end

    def photos
      payload = @client.upload_photo @data["photo"][0], :title => @data["title"], :description => @content
      format_post(payload)
    end

    def videos
    end

    def format_post(id)
      "#{@url}/#{id}"
    end

    private

    def oauth_params
      {
        :oauth_consumer_key => @consumer_key,
        :oauth_token => @token,
        :oauth_version => "1.0",
        :oauth_signature_method => 'HMAC-SHA1',
        :oauth_nonce => [OpenSSL::Random.random_bytes(32)].pack('m0').gsub(/\n$/,''),
        :oauth_timestamp => Time.now.to_i
      }
    end

    def call_flickr(method, domain, params, upload = false)
      params = oauth_params.merge(params)
      photo = params[:photo]
      signature = sign(method, params)
      params[:oauth_signature] = signature
      params_norm = params.map { |k,v| "#{escape(k.to_s)}=#{escape(v.to_s)}" }.sort.join('&')
      url = "#{domain}?#{params_norm}"
      puts url
      puts params
      puts photo
      if upload
        payload = RestClient.post(domain, params)
      else
        payload = RestClient::Request.execute(method: method, url: url)
      end
    end

    def sign(method, params)
      params.delete(:photo)
      params_norm = params.map { |k,v| "#{escape(k.to_s)}=#{escape(v.to_s)}" }.sort.join('&')
      text = "#{method.to_s.upcase}&#{escape(@domain)}&#{escape(params_norm)}"
      key = "#{escape(@consumer_secret)}&#{escape(@token_secret)}"
      digest = OpenSSL::Digest::SHA1.new
      [OpenSSL::HMAC.digest(digest, key, text)].pack('m0').gsub(/\n$/,'')
    end

    def encode_value(v)
      v = v.to_s.encode('utf-8').force_encoding('ascii-8bit') if RUBY_VERSION >= '1.9'
      v.to_s
    end

    def escape(s)
      encode_value(s).gsub(/[^a-zA-Z0-9\-\.\_\~]/) do |special|
        special.unpack("C*").map { |i| sprintf("%%%02X", i) }.join
      end
    end

  end
end
