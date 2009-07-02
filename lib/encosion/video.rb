module Encosion
  
  class Video < Base
    
    SERVER = 'api.brightcove.com'
    PORT = 80
    SECURE = false
    READ_PATH = '/services/library'
    WRITE_PATH = '/services/post'
    ENUMS = { :economics => { :free => 'FREE', :ad_supported => 'AD_SUPPORTED'}}
    
    attr_accessor(:name, 
                  :short_description, 
                  :long_description,
                  :link_url, 
                  :link_text, 
                  :tags, 
                  :reference_id, 
                  :economics,
                  :file)
      attr_reader(:id, 
                  :account_id, 
                  :flv_url,
                  :creation_date, 
                  :published_date, 
                  :last_modified_date, 
                  :video_still_url, 
                  :thumbnail_url, 
                  :length, 
                  :plays_total, 
                  :plays_trailing_week)
    
    # 
    # Class methods
    #
    class << self
      
      # Find a video by reference_id. Invokes Brightcove Media API command 'find_video_by_reference_id' or
      # 'find_videos_by_reference_ids' depending on whether you call one or multiple ids
      #
      #   Encosion::Video.find_by_reference_id('mycompany_1',:read_token => 'asdf')
      #   Encosion::Video.find_by_reference_id('mycompany_1','mycompany_2','mycompany_3',:read_token => 'asdf')
      
      def find_by_reference_id(*args)
        options = extract_options(args)
        ids = args.flatten.compact.uniq

        case ids.size
          when 0
            raise AssetNotFound, "Couldn't find #{self.class} without a reference ID"
          when 1
            options.merge!({:reference_id => ids.first})
            response = get(SERVER,PORT,READ_PATH,SECURE,'find_video_by_reference_id',options)
            return self.parse(response)
          else
            options.merge!({:reference_ids => ids.join(',')})
            response = get(SERVER,PORT,READ_PATH,SECURE,'find_videos_by_reference_ids',options)
            return self.parse(response)
          end
      end
      
      # Find a video by text search. Invokes Brightcove Media API command 'find_videos_by_text'
      #
      #   Encosion::Video.find_by_text('funny videos',:read_token => 'asdf')
      
      def find_by_text(*args)
        options = extract_options(args)
        text = args.flatten.compact.uniq
        raise AssetNotFound, "Couldn't find #{self.class} without text" if text == ''
        options.merge!({:text => text.first})
        response = get(SERVER,PORT,READ_PATH,SECURE,'find_videos_by_text',options)
        return response['items'].collect { |item| self.parse(item) }
      end
      

      # Find videos related to the given video_id. Invokes Brightcove Media API command 'find_related_videos'
      #
      #   Encosion::Video.find_related(123456,:read_token => 'asdf')
      
      def find_related(*args)
        options = extract_options(args)
        raise AssetNotFound, "Cannot find related #{self.class}s without a video_id or reference_id" if options[:video_id].nil? && options[:reference_id].nil?
        response = get(SERVER,PORT,READ_PATH,SECURE,'find_related_videos',options)
        return response['items'].collect { |item| self.parse(item) }
      end
      
      
      # Find a video by tag search. Invokes Brightcove Media API command 'find_videos_by_tags'
      #
      #   Encosion::Video.find_by_tags('bloopers','gagreel','funny',:read_token => 'asdf')
      
      def find_by_tags(*args)
        options = extract_options(args)
        tags = args.flatten.compact.uniq

        case tags.size
          when 0
            raise AssetNotFound, "Couldn't find #{self.class} without tags"
          else
            options.merge!({:and_tags => tags.join(',')})
            response = get(SERVER,PORT,READ_PATH,SECURE,'find_videos_by_tags',options)
            return response['items'].collect { |item| self.parse(item) }
          end
      end

      protected
        # Find some videos by ids
        def find_one(id, options)
          options.merge!({:video_id => id})
          response = get(SERVER,PORT,READ_PATH,SECURE,'find_video_by_id',options)
          return self.parse(response)
        end
      
       
        # Find mutliple videos by id
        def find_some(ids, options)
          options.merge!({:video_ids => ids.join(',')})
          response = get(SERVER,PORT,READ_PATH,SECURE,'find_videos_by_ids',options)
          puts response
          return response['items'].collect { |item| self.parse(item) }
        end
      
      
        # Find all videos
        def find_all(options)
          response = get(SERVER,PORT,READ_PATH,SECURE,'find_all_videos',options)
          return response['items'].collect { |item| self.parse(item) }
        end

      
        # Creates a new Video object from a Ruby hash (used to create a video from a parsed API call)
        def parse(obj)
          args = {:id => obj['id'].to_i,
                  :name => obj['name'],
                  :short_description => obj['shortDescription'],
                  :long_description => obj['longDescription'],
                  :creation_date => Time.at(obj['creationDate'].to_i/1000),
                  :published_date => Time.at(obj['publishedDate'].to_i/1000),
                  :last_modified_date => Time.at(obj['lastModifiedDate'].to_i/1000),
                  :link_url => obj['linkURL'],
                  :link_text => obj['linkText'],
                  :tags => obj['tags'],
                  :video_still_url => obj['videoStillURL'],
                  :thumbnail_url => obj['thumbnailURL'],
                  :reference_id => obj['referenceID'],
                  :length => obj['length'].to_i,
                  :economics => obj['economics'] ? ENUMS[:economics].find { |key,value| value == obj['economics'] }.first : nil,
                  :plays_total => obj['playsTotal'].to_i,
                  :plays_trailing_week => obj['playsTrailingWeek'].to_i } unless obj.nil?
          return self.new(args)
        end
      
    end
        
    #
    # Instance methods
    #
    def initialize(args={})
      @id = args[:id]
      @name = args[:name]
      @short_description = args[:short_description]
      @long_description = args[:long_description]
      @creation_date = args[:creation_date]
      @published_date = args[:published_date]
      @last_modified_date = args[:last_modified_date]
      @link_url = args[:link_url]
      @link_text = args[:link_text]
      @tags = args[:tags]
      @video_still_url = args[:video_still_url]
      @thumbnail_url = args[:thumbnail_url]
      @reference_id = args[:reference_id]
      @length = args[:length]
      @economics = args[:economics]
      @plays_total = args[:plays_total]
      @plays_trailing_week = args[:plays_trailing_week]
      @file = args[:file]
    end
    
    
    # Saves a video to Brightcove. Returns the Brightcove ID for the video that was just uploaded.
    def save(options={})
      # check to make sure we have everything needed for a create_video call
      raise NoFile, "You need to attach a file to this video before you can upload it: Video.file = File.new('/path/to/file')" if @file.nil?
      options.merge!({ 'video' => self.to_brightcove })   # take the parameters of this video and make them a valid video object for upload
      response = post(SERVER,PORT,WRITE_PATH,SECURE,'create_video',options,self)
      return response['result']    # returns the Brightcove ID of the video that was just uploaded
    end
    
    
    # Output the video as JSON
    def to_json
      { :id => @id,
        :name => @name,
        :short_description => @short_description,
        :long_description => @long_description,
        :creation_date => @creation_date,
        :published_date => @published_date,
        :last_modified_date => @last_modified_date,
        :link_url => @link_url,
        :link_text => @link_text,
        :tags => @tags,
        :video_still_url => @video_still_url,
        :thumbnail_url => @thumbnail_url,
        :reference_id => @reference_id,
        :length => @length,
        :economics => @economics,
        :plays_total => @plays_total,
        :plays_trailing_week => @plays_trailing_week }.to_json
    end
    
    # Outputs the video object into Brightcove's expected format
    def to_brightcove
      { 'name' => @name,
        'shortDescription' => @short_description,
        'longDescription' => @long_description,
        'linkURL' => @link_url,
        'linkText' => @link_text,
        'tags' => @tags,
        'referenceId' => @reference_id,
        'economics' => ENUMS[:economics][@economics] }
    end
    
    
    # Makes sure that the economics set on this video is one of a predetermined list
    def encosion=(sym)
      if ENUMS[:economics].has_key?(sym)
        raise EncosionError::InvalidEconomicsValue, "A video's economics value must be one of #{ENUMS[:economics].collect { |key,value| e.key }.join(',')}"
      else
        @economics = sym
      end
    end
    
  end
  
end
