require 'logger'

class YoutubeG
  # Extension of the base ruby Logger class to restore the default log
  # level and timestamp formatting which is so rudely taken forcibly
  # away from us by the Rails app's use of the ActiveSupport library
  # that wholesale-ly modifies the Logger's format_message method.
  #
  class Logger < ::Logger
    private
      begin
        # restore original log formatting to un-screw the screwage that is
        # foisted upon us by the activesupport library's clean_logger.rb
        alias format_message old_format_message

      rescue NameError
        # nothing for now -- this means we didn't need to alias since the
        # method wasn't overridden
      end
  end
end
