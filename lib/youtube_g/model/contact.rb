class YouTubeG
  module Model
    class Contact < YouTubeG::Record
      # *String*:: Identifies the status of a contact.
      #
      # * The tag's value will be accepted if the authenticated user and the contact have marked each other as friends.
      # * The tag's value will be requested if the contact has asked to be added to the authenticated user's contact list, but the request has not yet been accepted (or rejected).
      # * The tag's value will be pending if the authenticated user has asked to be added to the contact's contact list, but the request has not yet been accepted or rejected.
      #
      attr_reader :status
      
      # *String*:: The Youtube username of the contact.
      attr_reader :username
    end
  end
end
