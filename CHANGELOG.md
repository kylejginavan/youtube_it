2.3.x 2013-xx-xx
----------------

Changes:
- All YouTubeIt errors are now defined under the YouTubeIt namespace and inherit from YouTubeIt::Error
- All 404 responses from the YouTube api now raise YouTubeIt::ResourceNotFoundError instead of UploadError

Improvements:
- Added this CHANGELOG
