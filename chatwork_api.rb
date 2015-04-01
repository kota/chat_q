# encoding: utf-8

require 'net/https'
require 'uri'
require 'json'

class ChatworkAPI
  BASE_URL = 'https://api.chatwork.com/v1'

  def initialize
    @api_token = File.open('.chatwork_api_token','r'){|f| f.readline}
  end

  def get_status
    get('/my/status')
  end

  def get_rooms
    rooms = get('/rooms')
    rooms.map { |r| "id=#{r['room_id']}, name=#{r['name']}" }
  end

  def get_room(room_id)
    room = get("/rooms/#{room_id}")
    puts room
    room
  end

  def get_room_members(room_id)
    members = get("/rooms/#{room_id}/members")
    puts members
    members
  end

  def post_task(room_id, body, ids)
    task = post("/rooms/#{room_id}/tasks", { body: body, to_ids: ids.join(',') })
    puts task
    task
  end

  def get_messages(room_id)
    messages = get("/rooms/#{room_id}/messages")
    puts messages
    messages
  end

  def post_message(room_id, body)
    post("/rooms/#{room_id}/messages", { body: body })
  end

  private
  def https
    https = Net::HTTP.new('api.chatwork.com', 443)
    https.use_ssl = true
    https 
  end

  def header
    { 'X-ChatWorkToken' => @api_token }
  end

  def get(path)
    response = https.get("/v1#{path}", header)
    if response.body
      JSON.parse(response.body)
    else
      nil
    end
  end

  def post(path, params)
    query_string = params.map{|k,v| URI.encode(k.to_s) + "=" + URI.encode(v.to_s) }.join("&")
    response = https.post("/v1#{path}", query_string, header)
    JSON.parse(response.body)
  end
end
