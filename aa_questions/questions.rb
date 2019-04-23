require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end


class User
    attr_reader :fname, :lname, :id

    def self.all 
        data = QuestionsDBConnection.instance.execute("SELECT * FROM users")
        data.map { |datum| User.new(datum) }
    end

    def self.find_by_id(id) 
        user = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL
        User.new(user.first)
    end

    def self.find_by_name(fname, lname)
         user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        User.new(user.first)
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

# TEST LATER AUTHORED QUESTIONS
    def authored_questions
        Question.find_by_author_id(id)
        # question = QuestionsDBConnection.instance.execute(<<-SQL, id)
        # SELECT 
        #     * 
        # FROM 
        #     questions
        # WHERE
        #     author_id = ?
        # SQL
        # question
    end

    def followed_questions

    end

    def authored_replies
        replies = QuestionsDBConnection.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
         reply_id = ?
        SQL
        replies.map {|reply| Reply.new(reply) }
    end

    def insert 
        raise "#{self} already in database" if self.id
        QuestionsDBConnection.instance.execute(<<-SQL, self.fname, self.lname)
            INSERT INTO 
                users(fname, lname)
            VALUES
                (?, ?)
        SQL
    end

    def update
      raise "#{self} not in database" unless self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.fname, self.lname)
        UPDATE
            users
        SET
            fname = ?, lname = ?
        WHERE
            id = ?
        SQL
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id (self.id)
    end
    
   

end


class Question

    def self.all 
        data = QuestionsDBConnection.instance.execute("SELECT * FROM questions")
        data.map { |datum| Question.new(datum) }
    end

    def self.find_by_id 
        question = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL
        Question.new(question.first)
    end

    def self.find_by_author_id(author_id)
        questions = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?
        SQL
        questions.map { |question| Question.new(question) }
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def author
        authors = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?           
        SQL
        
        authors.map {|author| User.new(author)}
    end

    def replies
        replies = QuestionsDBConnection.instance.execute(<<-SQL, id)
        SELECT 
            *
        FROM 
            replies 
        WHERE 
            question_id = ?
        SQL

        replies.map {|reply| Reply.new(reply)}
    end 

    def insert 
        raise "#{self} already in database" if self.id
        QuestionsDBConnection.instance.execute(<<-SQL, self.title, self.body, self.author_id)
            INSERT INTO 
                questions(title, body)
            VALUES
                (?, ?, ?)
        SQL
    end

    def update
      raise "#{self} not in database" unless self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.title, self.body, self.author_id)
        UPDATE
            questions
        SET
            title = ?, body = ?, author_id = ?
        WHERE
            id = ?
        SQL
    end

    def followers 
        QuestionFollow.followers_for_question_id (self.id)
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

end

class QuestionFollow
  def self.all 
        data = QuestionsDBConnection.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollow.new(datum) }
    end

    def self.find_by_id 
        question_follow = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                QuestionFollows
            WHERE
                id = ?
        SQL
        QuestionFollow.new(question_follow.first)
    end

    def self.followers_for_question_id (question_id)
        question_followers = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                users
            JOIN 
                question_follows ON question_follows.user_id = users.id
            WHERE
                question_follows.question_id = ?
        SQL
        question_followers.map {|follower| User.new(follower)}
    end

    def self.followed_questions_for_user_id (user_id)
        questions = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                questions
            JOIN 
                question_follows ON question_follows.question_id = questions.id
            WHERE
                question_follows.user_id = ?
        SQL
        questions.map { |question| Question.new(question) }
    end
    
    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @user_id = options['user_id']
    end

    def insert 
        raise "#{self} already in database" if self.id
        QuestionsDBConnection.instance.execute(<<-SQL, self.question_id, self.user_id)
            INSERT INTO 
                users(question_id, user_id)
            VALUES
                (?, ?)
        SQL
    end

    def update
      raise "#{self} not in database" unless self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.question_id, self.user_id)
        UPDATE
            users
        SET
            question_id = ?, user_id = ?
        WHERE
            id = ?
        SQL
    end

    def self.most_followed_questions(n)
        questions =  QuestionsDBConnection.instance.execute(<<-SQL)
            SELECT
                COUNT(question_id)
            FROM
                question_follows
            GROUP BY question_id
            ORDER BY COUNT(question_id) DESC
            LIMIT n
        SQL
        questions.map {|question| Question.new(question)}
    end

end

class Reply
    attr_accessor :id, :reply_id, :parent_reply, :question_id
    
    def self.all 
        data = QuestionsDBConnection.instance.execute("SELECT * FROM replies")
        data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_id(id)
        reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL
        Reply.new(reply.first)
    end
    
    def self.find_by_user_id(user_id)
         reply = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies
            WHERE
                user_id = ?
        SQL
        Reply.new(reply.first)
    end 


    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @parent_id = options['parent_id']
        @reply_id = options['reply_id']
        @body = options['body']
    end

    def insert 
        raise "#{self} already in database" if self.id
        QuestionsDBConnection.instance.execute(<<-SQL, self.question_id, self.parent_id, self.reply_id, self.body)
            INSERT INTO 
                replies(question_id, parent_id, reply_id, body)
            VALUES
                (?, ?, ?, ?)
        SQL
    end

    def update
      raise "#{self} not in database" unless self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.question_id, self.parent_id, self.reply_id, self.body)
        UPDATE
            replies
        SET
            question_id = ?, parent_id = ?, reply_id = ?, body = ?
        WHERE
            id = ?
        SQL
    end

    def author 
        author = QuestionsDBConnection.instance.execute(<<-SQL, reply_id)
        SELECT 
            *
        FROM
            users
        WHERE
            id = ?
        SQL
        authors.map {|author| User.new(author)}
    end

    def question 
        questions = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            questions
        WHERE
            id = ?
        SQL
        questions.map {|question| Question.new(question)}
    end

    def parent_reply
        parents = QuestionsDBConnection.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
            reply_id = ?
        SQL
        parents.map {|parent| Reply.new(parent)}
    end

    def child_replies
        children = QuestionsDBConnection.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
            parent_id = ?
        SQL
        children.map {|child| Reply.new(child)}
    end

    #
end

class QuestionLike

    def self.all 
        data = QuestionsDBConnection.instance.execute("SELECT * FROM question_like")
        data.map { |datum| QuestionLike.new(datum) }
    end

    def self.find_by_id 
        question_like = QuestionsDBConnection.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_likes
            WHERE
                id = ?
        SQL
        QuestionLike.new(question_like.first)
    end

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def insert 
        raise "#{self} already in database" if self.id
        QuestionsDBConnection.instance.execute(<<-SQL, self.user_id, self.question_id)
            INSERT INTO 
                question_likes(user_id, question_id)
            VALUES
                (?, ?)
        SQL
    end

    def update
      raise "#{self} not in database" unless self.id
      QuestionsDBConnection.instance.execute(<<-SQL, self.user_id, self.question_id)
        UPDATE
            question_likes
        SET
            user_id = ?, question_id = ?
        WHERE
            id = ?
        SQL
    end

end