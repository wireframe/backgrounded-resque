require File.join(File.dirname(__FILE__), 'test_helper')
require 'resque_unit'

ActiveRecord::Schema.define(:version => 1) do
  create_table :blogs, :force => true do |t|
    t.column :name, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
  end

  create_table :posts, :force => true do |t|
    t.column :title, :string
  end
end

class ResqueHandlerTest < Test::Unit::TestCase
  class User < ActiveRecord::Base
    def do_stuff
    end
  end

  class Post < ActiveRecord::Base
    def do_stuff
    end
  end

  class Blog < ActiveRecord::Base
    class << self
      def do_stuff
      end
    end
    def do_stuff
    end
  end

  context '.queue' do
    should "default to #{Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE}" do
      assert_equal Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE, Backgrounded::Resque::ResqueHandler.queue
    end
    should 'be used by resque to determine job queue' do
      assert_equal Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE, Resque.queue_from_class(Backgrounded::Resque::ResqueHandler)
    end
  end

  context 'when backgrounded is configured with resque' do
    setup do
      Resque.reset!
      @handler = Backgrounded::Resque::ResqueHandler.new
      Backgrounded.handler = @handler
    end

    context 'a class level backgrounded method' do
      context "invoking backgrounded method" do
        setup do
          Blog.backgrounded.do_stuff
        end
        should "enqueue job to resque" do
          assert_queued Backgrounded::Resque::ResqueHandler, [Blog.to_s, -1, 'do_stuff']
          assert_equal Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE, Resque.queue_from_class(Backgrounded::Resque::ResqueHandler)
        end
        context "running background job" do
          setup do
            Blog.expects(:do_stuff)
            Resque.run!
          end
          should "invoke method on class" do end #see expectations
        end
      end
      context 'with an instance level backgrounded method of the same name' do
        setup do
          @blog = Blog.create
          @blog.backgrounded.do_stuff
        end
        should "enqueue instance method job to resque" do
          assert_queued Backgrounded::Resque::ResqueHandler, [Blog.to_s, @blog.id, 'do_stuff']
          assert_equal Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE, Resque.queue_from_class(Backgrounded::Resque::ResqueHandler)
        end
        context "running background job" do
          setup do
            Blog.expects(:do_stuff).never
            Blog.any_instance.expects(:do_stuff)
            Resque.run!
          end
          should "invoke method on instance" do end #see expectations
        end
      end
    end

    module Foo
      def self.bar
      end
    end

    context 'a module with backgrounded method' do
      setup do
        Foo.expects(:bar)
        Foo.backgrounded.bar
        Resque.run!
      end
      should 'invoke module class method in background' do end # see expectations
    end

    context 'a persisted object with a single backgrounded method' do
      setup do
        @user = User.create
      end
      context "invoking backgrounded method" do
        setup do
          @user.backgrounded.do_stuff
        end
        should "enqueue job to resque" do
          assert_queued Backgrounded::Resque::ResqueHandler, [User.to_s, @user.id, 'do_stuff']
          assert_equal Backgrounded::Resque::ResqueHandler::DEFAULT_QUEUE, Resque.queue_from_class(Backgrounded::Resque::ResqueHandler)
        end
        context "running background job" do
          should "invoke method on user object" do
            User.any_instance.expects(:do_stuff)
            Resque.run!
          end
        end
      end

      context 'a persisted object with backgrounded method with options' do
        setup do
          @post = Post.create
        end
        context "invoking backgrounded method" do
          setup do
            @post.backgrounded(:queue => 'important').do_stuff
          end
          should "use configured queue" do
            assert_equal 'important', Backgrounded::Resque::ResqueHandler.queue
            assert_equal 'important', Resque.queue_from_class(Backgrounded::Resque::ResqueHandler)
            assert_equal 1, Resque.queue('important').length
          end
        end
      end
    end
  end
end
