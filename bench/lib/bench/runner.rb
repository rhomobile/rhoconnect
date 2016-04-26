module Bench
  class Runner
    include Logging
    include Timer
    attr_reader :threads

    def initialize
      @threads = []
      @sessions = []
    end

    def test(concurrency,iterations,&block)
      total_times = times do
        0.upto(concurrency - 1) do |thread_id|
          #sleep rand(2)
          threads << Thread.new(block) do |t|
            0.upto(iterations - 1) do |iteration|
              s = Session.new(thread_id, iteration)
              @sessions << s
              begin
                yield Bench,s
              rescue Exception => e
                puts "error running script: #{e.inspect}"
                puts e.backtrace.join("\n")
              end
            end
          end
        end
        begin
          threads.each { |t| t.join }
        rescue RestClient::RequestTimeout => e
          bench_log "Request timed out #{e}"
        end
      end
      Bench.sessions = @sessions
      Bench.total_time = total_times[0]
      Bench.start_time = total_times[1]
      Bench.end_time = total_times[2]
    end
  end
end
