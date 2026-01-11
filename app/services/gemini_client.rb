require 'net/http'
require 'uri'
require 'json'

class GeminiClient
  def self.generate(prompt)
    api_key = ENV['GEMINI_API_KEY']
    return "API Key is missing!" if api_key.nil?

    # リストにあった正確なモデル名（models/接頭辞付き）を使用
    target_model = "models/gemini-flash-latest"
    # target_model = "models/gemini-2.0-flash"
    url = "https://generativelanguage.googleapis.com/v1beta/#{target_model}:generateContent?key=#{api_key}"
    uri = URI.parse(url)
    
    header = { 'Content-Type' => 'application/json' }
    body = {
      contents: [{
        parts: [{ text: prompt }]
      }]
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = body.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    # 成功時はテキストを返し、失敗時はエラー内容を詳しく出す
    if result["error"]
      "Error: #{result['error']['message']}"
    else
      result.dig("candidates", 0, "content", "parts", 0, "text") || "Response structure mismatch: #{result}"
    end
  rescue => e
    "Exception: #{e.message}"
  end
end
