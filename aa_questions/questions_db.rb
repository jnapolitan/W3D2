require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  attr_reader :id
  
  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end 
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
    
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    
    return nil if user.empty?
    User.new(user.first)
  end
  
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL
    
    return nil if user.empty?
    User.new(user.first)
  end
  
  def authored_questions
    questions = Question.find_by_user_id(self.id)
    return nil if questions.empty?
    questions
  end
  
  def authored_replies
    replies = Reply.find_by_user_id(self.id)  
    return nil if replies.empty?
    replies
  end
  
  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end 
  
  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end
  
  def average_karma
    likes = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    
    SELECT 
      COUNT(DISTINCT(questions.title)), COUNT(question_likes.id)
    FROM
      questions
    LEFT OUTER JOIN
      question_likes ON questions.id = question_likes.question_id
    WHERE
      questions.user_id = ?
    SQL
    
    val = likes.first.values
    val.first.fdiv(val.last)
  end 
  
  def save
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

end

# COUNT(DISTINCT(questions.title))

class Question
  attr_accessor :title, :body, :user_id
  attr_reader :id
  
  def self.all
    data1 = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data1.map { |datum| Question.new(datum) }
  end 
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end
  
  def self.find_by_id(id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, id)
    
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    
    return nil if questions.empty?
    Question.new(questions.first)
  end
  
  def self.find_by_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    
    SELECT
      *
    FROM
      questions
    WHERE
      user_id = ?
    SQL
    
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end
  
  def author
    authors = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
    
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    
    return nil if authors.empty?
    User.new(authors.first)
  end
  
  def replies
    replies = Reply.find_by_question_id(self.id)
    return nil if replies.empty?
    replies
  end
  
  def followers
    QuestionFollow.followers_for_question_id(1)
  end 
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end 
  
  def likers
    QuestionLike.likers_for_question_id(self.id)
  end
  
  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end
  
  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
end
  
class Reply 
  attr_accessor :question_id, :parent_id, :user_id, :body
  attr_reader :id
  
  def self.all
    data2 = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data2.map { |datum| Reply.new(datum) }
  end 
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
  end 
  
  def self.find_by_id(id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
    
    SELECT
      *
    FROM
      replies
    WHERE
      id = ?
    SQL
    
    return nil if replies.empty?
    Reply.new(replies.first)
  end
  
  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
    SQL
    
    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end 
  
  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    
    SELECT 
      *
    FROM 
      replies 
    WHERE 
      question_id = ?
    SQL
    
    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end 
  
  def author
    author = QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
    
    SELECT
      *
    FROM
      users
    WHERE
      id = ?
    SQL
    
    return nil if author.empty?
    User.new(author.first)
  end
  
  def question
    question = QuestionsDatabase.instance.execute(<<-SQL, self.question_id)
    
    SELECT
      *
    FROM
      questions
    WHERE
      id = ?
    SQL
    
    return nil if question.empty?
    Question.new(question.first)
  end
  
  def parent_reply 
    replies = QuestionsDatabase.instance.execute(<<-SQL, self.parent_id)
    
    SELECT
      *
    FROM
      replies 
    WHERE 
      id = ?
    SQL
    
    return nil if replies.empty?
    Reply.new(replies.first)
  end 
  
  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    
    SELECT
      *
    FROM
      replies 
    WHERE 
      parent_id = ?
    SQL
    
    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end 
end 

class QuestionFollow
  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    
    SELECT 
      *
    FROM
      users
    JOIN
      question_follows ON users.id = question_follows.user_id
    WHERE
      question_id = ?
    SQL
    
    return nil if followers.empty?
    followers.map { |follower| User.new(follower) }
  end
  
  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    
    SELECT 
      *
    FROM
      questions
    JOIN
      question_follows ON questions.id = question_follows.question_id
    WHERE
      question_follows.user_id = ?
    SQL
    
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end  
  
  def self.most_followed_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
  
    SELECT 
      title, COUNT(question_follows.user_id)
    FROM 
      questions 
    JOIN 
      question_follows ON questions.id = question_follows.question_id
    GROUP BY 
      title 
    ORDER BY
      COUNT(question_follows.user_id) DESC 
    LIMIT ?
    
    SQL
    
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end 
end

class QuestionLike
  
  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    
    SELECT 
      *
    FROM
      users
    JOIN
      question_likes ON users.id = question_likes.user_id
    WHERE
      question_id = ?
    SQL
    
    return nil if likers.empty?
    likers.map { |liker| User.new(liker) }
  end 
  
  def self.num_likes_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    
    SELECT 
      COUNT(users.id)
    FROM
      users
    JOIN
      question_likes ON users.id = question_likes.user_id
    WHERE
      question_id = ?
    SQL
    
    likers.first.values.first
  end 
  
  def self.liked_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    
    SELECT
      *
    FROM
      questions
    JOIN
      question_likes ON questions.id = question_likes.question_id
    WHERE
      question_likes.user_id = ?
    SQL
    
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end
  
  def self.most_liked_questions(n)
    questions = QuestionsDatabase.instance.execute(<<-SQL, n)
  
    SELECT 
      title, COUNT(question_likes.user_id)
    FROM 
      questions 
    JOIN 
      question_likes ON questions.id = question_likes.question_id
    GROUP BY 
      title 
    ORDER BY
      COUNT(question_likes.user_id) DESC 
    LIMIT ?
    SQL
    
    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end 
end 
