require './chatwork_api'
require 'nkf'
require 'json'

class Problem
  attr_accessor :text, :answer

  def initialize(text,answer)
    @text = text
    @answer = answer
  end

  def to_s
    "text=#{text}, answer=#{answer}"
  end

  def is_answer_correct(answer)
     answer = NKF.nkf("-wh1Z", answer.strip).downcase
     correct_answer = NKF.nkf("-wh1Z", @answer.strip).downcase
     answer == correct_answer
  end
end

class Quiz
  attr_accessor :problems

  TIME_LIMIT_SEC = 20

  def initialize
    @chatwork = ChatworkAPI.new
    read_problems
    read_scores
  end

  def read_problems
    lines = File.open('./problem.csv','r') do |f|
      f.readlines
    end
    @problems = lines.map do |l|
      csv = l.split(',')
      Problem.new(csv[0],csv[1])
    end
  end

  def read_scores
    unless File.exist?('./score.txt')
      File.open('./score.txt','w') { |f| f.write("{}") }
    end
    json_str = File.open('./score.txt','r') do |f|
      f.read
    end
    @scores = JSON.parse(json_str)
  end

  def start
    problem = @problems.sample

    puts_chatwork "問題:#{problem.text}"

    start_time = Time.now
    @finished = false

    thread = Thread.new do
      last_requested_at = Time.now
      while true
        break if @finished
        current_time = Time.now
        if current_time - last_requested_at > 1
          last_requested_at = current_time
          answers = get_lines_chatwork
          if answers
            answers.each do |answer|
              if problem.is_answer_correct(answer['body'])
                name = answer['account']['name']
                increment_score(name)
                puts_name_and_score(name)
                @finished = true
                break
              end
            end
          else
            puts "答えが入力されていません"
          end
        end
      end
    end

    while true
      break if @finished
      elapsed = Time.now - start_time
      if elapsed > TIME_LIMIT_SEC
        @finished = true
        thread.join
        puts_chatwork "時間切れです。正解:#{problem.answer}"
        break
      end
    end
  end

  def puts_chatwork(str)
    @chatwork.post_message("28293593",str)
  end

  def get_lines_chatwork
    @chatwork.get_messages("28293593")
  end

  def puts_name_and_score(name)
    str = "#{name}さん。正解です"
    str += "\n\nこれまでの成績\n"
    @scores.each do |name,score|
      str += "#{name}:#{score}点\n"
    end
    puts_chatwork(str)
  end

  def increment_score(name)
    @scores[name] ||= 0
    @scores[name] += 1
    File.open('./score.txt','w') do |f|
      f.write(@scores.to_json)
    end
  end
end

q = Quiz.new
q.read_problems

while true
  q.start
  sleep 480
end
