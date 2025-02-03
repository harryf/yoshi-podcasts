from http.server import HTTPServer, SimpleHTTPRequestHandler
import os
from urllib.parse import unquote, quote
import mimetypes
import sys
import time
import json

class MediaHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        # Handle health check endpoint
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header("Access-Control-Allow-Origin", "http://localhost:4000")
            self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
            self.end_headers()
            health_info = {
                "status": "running",
                "allowed_volumes": self.server.allowed_volumes
            }
            self.wfile.write(json.dumps(health_info).encode())
            return
            
        # Skip processing if it's the root path
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"Media server running")
            return

        # Clean and decode the path
        clean_path = self.path.strip('/')  # Remove leading/trailing slashes
        decoded_path = unquote(unquote(clean_path))  # Handle double-encoded URLs
        
        # Ensure the path starts with a forward slash for absolute path
        if not decoded_path.startswith('/'):
            decoded_path = '/' + decoded_path
        
        # Debug logging
        print(f"\nRequest details:")
        print(f"Original path: {self.path}")
        print(f"Cleaned path: {clean_path}")
        print(f"Decoded path: {decoded_path}")
        print(f"Allowed volumes: {self.server.allowed_volumes}")
        
        # Security check - only allow access to specific directories
        allowed_prefixes = self.server.allowed_volumes
        is_allowed = any(decoded_path.startswith(prefix) for prefix in allowed_prefixes)
        
        if not is_allowed:
            error_msg = (
                f"Access denied. Path {decoded_path} not in allowed directories: "
                f"{', '.join(allowed_prefixes)}"
            )
            print(f"Access denied: {error_msg}")
            self.send_error(403, error_msg)
            return

        if not os.path.exists(decoded_path):
            error_msg = f"File not found: {decoded_path}"
            print(f"Not found: {error_msg}")
            self.send_error(404, error_msg)
            return

        if not os.path.isfile(decoded_path):
            error_msg = f"Not a file: {decoded_path}"
            print(f"Not a file: {error_msg}")
            self.send_error(403, error_msg)
            return

        try:
            # Guess the content type from the decoded path
            content_type, _ = mimetypes.guess_type(decoded_path)
            if content_type is None:
                content_type = 'application/octet-stream'

            f = open(decoded_path, 'rb')
            print(f"Successfully opened file: {decoded_path}")
            print(f"Content-Type: {content_type}")
        except Exception as e:
            error_msg = f"Error opening file: {str(e)}"
            print(f"Error: {error_msg}")
            self.send_error(500, error_msg)
            return

        try:
            self.send_response(200)
            self.send_header("Content-type", content_type)
            
            # Add CORS headers to allow local access
            self.send_header("Access-Control-Allow-Origin", "http://localhost:4000")
            self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
            
            fs = os.fstat(f.fileno())
            self.send_header("Content-Length", str(fs[6]))
            self.end_headers()
            
            self.copyfile(f, self.wfile)
            print(f"Successfully served file: {decoded_path}")
        finally:
            f.close()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "http://localhost:4000")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.end_headers()

def check_volume_access(volume_paths):
    """Check if volumes are accessible and return only the accessible ones."""
    accessible = []
    inaccessible = []
    
    for path in volume_paths:
        if os.path.exists(path):
            try:
                # Try to list the directory to verify read access
                os.listdir(path)
                accessible.append(path)
            except Exception as e:
                inaccessible.append((path, str(e)))
        else:
            inaccessible.append((path, "Path does not exist"))
    
    return accessible, inaccessible

if __name__ == "__main__":
    PORT = 8000
    VOLUMES = [
        "/Volumes/T7/Yoshi Podcast",
        # Add other allowed directories here
    ]
    
    print(f"Starting media server on port {PORT}...")
    print("\nChecking volume access...")
    
    accessible_volumes, inaccessible_volumes = check_volume_access(VOLUMES)
    
    if not accessible_volumes:
        print("\nERROR: No accessible volumes found!")
        for path, error in inaccessible_volumes:
            print(f" {path}: {error}")
        print("\nPlease make sure:")
        print("1. External drives are properly connected")
        print("2. You have permission to access the directories")
        sys.exit(1)
    
    print("\nAccessible volumes:")
    for volume in accessible_volumes:
        print(f" {volume}")
    
    if inaccessible_volumes:
        print("\nInaccessible volumes:")
        for path, error in inaccessible_volumes:
            print(f" {path}: {error}")
    
    # Store the accessible volumes in the server instance
    httpd = HTTPServer(('localhost', PORT), MediaHandler)
    httpd.allowed_volumes = accessible_volumes
    
    print(f"\nServer running at http://localhost:{PORT}")
    print("Health check endpoint: http://localhost:{PORT}/health")
    print("Press Ctrl+C to stop")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.server_close()
