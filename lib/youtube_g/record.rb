class YoutubeG
  # TODO: Does this require it's own file? Moved to video search request.
  class Record
    def initialize (params)
      return if params.nil?

      params.each do |key, value| 
        name = key.to_s
        instance_variable_set("@#{name}", value) if respond_to?(name)
      end
    end
  end
end
