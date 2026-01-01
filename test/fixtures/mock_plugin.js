// Mock Plugin for Stream App
// This mimics a real external plugin

var pluginManifest = {
  "id": "mock.plugin.v1",
  "version": "1.0.0",
  "name": "Mock Provider",
  "description": "Returns a test video stream for development.",
  "types": ["movie"],
  "idPrefixes": ["tt"]
};

async function getStreams(request) {
  console.log("Mock Plugin received request: " + JSON.stringify(request));

  // Simulate a network delay
  // In a real plugin, we would use fetch() to scrape a site
  // await fetch('https://google.com'); // Test the bridge

  if (request.type === 'movie' && request.title === 'Big Buck Bunny') {
    return [
      {
        "name": "4K | Mock",
        "description": "Big Buck Bunny Test Stream",
        "url": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "headers": {},
        "subtitles": []
      },
      {
         "name": "720p | Mock",
         "description": "Alternative Source",
         "url": "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
      }
    ];
  }

  return [];
}
