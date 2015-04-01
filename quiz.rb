require './chatwork_api'

class Problem
  attr_accessor :text, :answer

  def initialize(text,answer)
    @text = text
    @answer = answer
  end

  def to_s
    "text=#{text}, answer=#{answer}"
  end
end

class Quiz
  attr_accessor :problems

  def initialize
    @chatwork = ChatworkAPI.new
    read_problems
  end

  def read_problems
    lines = File.open('./problem.csv','r') do |f|
      f.readlines
    end
    @problems = lines.map do |l|
      csv = l.split(',')
      Problem.new(csv[1],csv[2])
    end
  end

  def start
    problem = @problems.sample

    puts_chatwork "問題:#{problem.text}"

    start_time = Time.now
    @finished = false

    thread = Thread.new do
      last_requested_at = Time.now
      while true
        current_time = Time.now
        if current_time - last_requested_at > 1
          last_requested_at = current_time
          answers = get_lines_chatwork
          if answers
            answers.each do |answer|
              if answer['body'].strip == problem.answer.strip
                puts_chatwork "#{answer['account']['name']}さん。正解です"
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
      if elapsed > 10
        thread.kill
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
end

q = Quiz.new
q.read_problems
q.start
