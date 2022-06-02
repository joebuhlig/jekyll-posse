require 'aws-sdk-s3'
require 'nokogiri'
require 'open-uri'
require 'mime-types'

module JekyllPosse
  class WebsitePosse

    def initialize(data = nil, content = nil, silo = nil, download = false)
      @data = data
      @content = content
      @url = silo
      @download = download
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
    end

    def videos
    end

    def download(url)
      data = collect_data(url)
      s3 = Aws::S3::Client.new(
        access_key_id: ENV["S3_ACCESS_KEY"],
        secret_access_key: ENV["S3_SECRET_KEY"],
        endpoint: ENV["S3_POSSE_ENDPOINT"],
        region: ENV["S3_POSSE_REGION"]
      )
      uri = URI.parse(url)
      hostname = uri.hostname
      file_type = MIME::Types.type_for(data[:web_icon].split('.').last).first
      ext = file_type.preferred_extension
      obj = Aws::S3::Object.new(client: s3, bucket_name: ENV["S3_POSSE_BUCKET"], key: "avatars/websites/#{hostname}.#{ext}")
      obj.upload_stream(acl: 'public-read', content_type: file_type.to_s) do |write_stream|
        IO.copy_stream(URI.open(data[:web_icon]), write_stream)
      end
      data[:avatar] = "avatars/websites/#{hostname}.#{ext}"
      FileUtils.mkdir_p("_data/websites/#{hostname}#{uri.path}") unless File.directory?("_data/websites/#{hostname}#{uri.path}")
      File.open("_data/websites/#{hostname}#{uri.path}data.json","w") do |f|
        f.write(data.to_json)
      end
      puts "Website info downloaded to: _data/websites/#{hostname}#{uri.path}data.json"
    end

    def collect_data(url)
      data = {}
      found_url = false
      favicon_urls = {}
      uri = URI.parse(url)
      hostname = uri.hostname

      doc = Nokogiri::HTML(URI.open(url))
      doc.css('link').each do |link|
        if %['shortcut icon', 'icon', 'shortcut'].include?(link['rel'])
          icon_url = URI::join(url, link['href']).to_s
          favicon_urls[icon_url] = link['sizes'].split.sort.last.split('x').first.to_i rescue []
          found_url = true
        end
      end
      favicon_urls[hostname] << [URI::join(url, '/favicon.ico').to_s, []] unless found_url
      sorted = favicon_urls.sort_by { |url, size| size }
      uri = URI.parse(sorted.last[0])
      uri.query = nil
      data[:web_icon] = uri.to_s
      data[:name] = hostname
      data[:title] = doc.css('title').first.content
      doc.css('meta').each do |meta|
        if meta['name'] == "description" or meta['property'] == "og:description" or meta['itemprop'] == "description" or meta['name'] == "twitter:description"
          data[:description] = meta['content']
        end
      end
      data
    end

  end
end
