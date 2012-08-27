require 'fileutils'
require 'tokenizer'
require 'rubygems'
require 'pdf-reader'
class QuestionsController < ApplicationController
  # GET /questions
  # GET /questions.json
  def parse()

    dir_files = Array.new
    path = params[:path]
    pdf_path = params[:pdf_path]
    txt_path = params[:txt_path]
    @dir_id = params[:dir_id]
    system("unoconv -fpdf /#{path}")
    Dir.chdir("/home/satsahib/office/text/app/assets/images/my_images")
    d = Dir.new("/home/satsahib/office/text/app/assets/images/my_images")
    d.each { |file|
      dir_files << file
    }
    if dir_files.include?(@dir_id)
      require 'fileutils'
      FileUtils.rm_rf "#{@dir_id}"
      FileUtils.mkdir "/home/satsahib/office/text/app/assets/images/my_images/#{@dir_id}"
      system("pdfimages -j /#{pdf_path} /home/satsahib/office/text/app/assets/images/my_images/#{@dir_id}/")
    else
      FileUtils.mkdir "/home/satsahib/office/text/app/assets/images/my_images/#{@dir_id}"
      system("pdfimages -j /#{pdf_path} /home/satsahib/office/text/app/assets/images/my_images/#{@dir_id}/")
    end

    reader = PDF::Reader.new("/#{pdf_path}")
    file_path = "/#{txt_path}"
    reader.pages.each do |page|
      File.open(file_path, "a") { |f| f.write(page.text)
        f.write("\n")}
    end
    #opening the file in the read mode
    file = File.open("#{txt_path}", "r")
    @cfi = 0
    while (line = file.gets)
      option = line.strip
      #regular expression for various parsers
      question_pattern1 =  /^\{?\[?\(?\:?[Q0-9-\*#\.\t]+[\)\]\/\.\}:]+[ \t]*[^\n]*$/
      question_pattern2 = /^\{?\[?\(?\:?[Q]+[\s]+[0-9-\*#\.\t]+[\)\]\/\.\}:]+[ \t]*[^\n]*$/
      question_pattern3 = /^\{?\[?\(?\:?[Q0-9]+[\s]+[\)\]\/\.\}:]+[ \t]*[^\n]*$/
      option_pattern =    /^\{?\[?\(?\:?[A-Ea-e-\*#\.\t]+[\)\]\/\.\}:]+[ \t]*[^\n]*$/
      correct_pattern = /^(Ans:|Answer:|Ans :|Answer :)+[ \t]*[^\n]*$/
      topic_pattern = /^(Topic:|topic:|topic :|Topic :)+[ \t]*[^\n]*$/
      sub_topic_pattern = /^(Sub-Topic:|Sub-topic:|sub-topic:|sub-Topic:|Sub-Topic :|Sub-topic :|sub-topic :|sub-Topic :)+[ \t]*[^\n]*$/
      tag_pattern = /^(Tags:|tags:|Tags :|tags :)+[ \t]*[^\n]*$/
      marks_pattern = /^(Marks:|marks:|Marks :|marks :)+[ \t]*[^\n]*$/
      direction_pattern = /^(Directions:|directions:|direction:|Direction:|Direction :|direction :|Directions :|directions :)+[ \t]*[^\n]*$/
      image_pattern = /^(<img>)$/
      passage_pattern = /^Passage:+[ \t]*[^\n]*$/
      roman_number_pattern = /^\{?\[?\(?\:?+(?i:(?=[MDCLXVI])((M{0,3})((C[DM])|(D?C{0,3}))?((X[LC])|(L?XX{0,2})|L)?((I[VX])|(V?(II{0,2}))|V)?))+[\)\]\/\.\}:]+[ \t]*[^\n]*$$/
      @to_pattern=""
      @to_pattern1=""
      @to_pattern2=""
      @to_pattern3=""
      @to_pattern4=""
      @to_pattern5=""

      #Different parsers being used
      if topic_pattern.match(option)
        topic_parser(option)
      elsif image_pattern.match(option)
        parser_image(option,@dir_id)
      elsif direction_pattern.match(option)
        @is_passage_question = false
        direction_parser(option)
      elsif marks_pattern.match(option)
        marks_parser(option)
      elsif tag_pattern.match(option)
        tag_parser(option)
      elsif sub_topic_pattern.match(option)
        subtopic_parser(option)
      elsif option_pattern.match(option)
        option_parser(option)
      elsif passage_pattern.match(option)
        passage_parser(option)
      elsif question_pattern1.match(option) or question_pattern2.match(option) or question_pattern3.match(option)
        question_parser(option)
        if (@m_d == "t") and (@is_passage_question == true)
          if @direction_diff > 0
            save_multi_direction_of_passage_and_question_type_for_vijay()
            @direction_diff = @direction_diff - 1
          end

        elsif (@m_d == "t") and (@is_passage_question == false)

          if @direction_diff > 0
            save_multi_direction_for_vijay()
            @direction_diff = @direction_diff - 1
          end

        elsif @m_d == "f"
          save_single_direction_for_vijay()
          @direction_single=""
        else
          save_no_direction_for_vijay()
        end

      elsif correct_pattern.match(option)
        correct_pattern_parser(option)
      else
        if @recent_pattern == "q"
          @concat_question = @recent_question_pattern + " " + option
          save_concat_question_for_vijay()
        elsif @recent_pattern == "a"
          @recent_pattern_option = @recent_pattern_option+" "+ option
          save_concat_answer_for_vijay()
        elsif @recent_pattern == "p"
          @recent_pattern_passage = @recent_pattern_passage+"\n"+option
          save_concat_passage_for_vijay()
        elsif @recent_pattern == "md"
          @recent_pattern_multi_direction = @recent_pattern_multi_direction+" "+option
          save_md_for_vijay()
        elsif @recent_pattern == "sd"
          @recent_pattern_single_direction = @recent_pattern_single_direction+" "+option
          save_sd_for_vijay()
        else
          error = Error.new
          error.name = option
          error.save
        end

      end
    end
    FileUtils.rm txt_path
    FileUtils.rm pdf_path
    FileUtils.rm path
    redirect_to :action => :index
  end

  def tokenize_option(question,a,b,c,d,e)
    #to update the question table attribute "ans_status" to "ans"
    save_ans_status_to_ans_for_vijay(question)
    if !a.nil?
      aa = a.strip
    end
    if !b.nil?
      bb = b.strip
    end
    if !c.nil?
      cc = c.strip
    end
    if !d.nil?
      dd = d.strip
    end
    if !e.nil?
      ee = e.strip
    end
    tokenizer = Tokenizer::Tokenizer.new
    op = Answer.find_all_by_question_id(question.id)
    correct_count = 0
    op.each do |o|
      opt = o.answer
      to = tokenizer.tokenize(opt)
      if to[0]== aa or to[1]==aa
        ans = Answer.find(o.id)
        save_status_correct_for_option_vijay(ans)
        correct_count = correct_count + 1
      end

      if to[0]== bb or to[1]==bb
        ans = Answer.find(o.id)
        save_status_correct_for_option_vijay(ans)
        correct_count = correct_count + 1
      end

      if to[0]== cc or to[1]==cc
        ans = Answer.find(o.id)
        save_status_correct_for_option_vijay(ans)
        correct_count = correct_count + 1
      end

      if to[0]== dd or to[1]==dd
        ans = Answer.find(o.id)
        save_status_correct_for_option_vijay(ans)
        correct_count = correct_count + 1
      end

      if to[0]== ee or to[1]==ee
        ans = Answer.find(o.id)
        save_status_correct_for__option_vijay(ans)
        correct_count = correct_count + 1
      end

    end

    if (correct_count == 1) and (question.passage_id.nil?)
      save_question_type_mcq_for_vijay(question)

    elsif (correct_count > 1 ) and (question.passage_id.nil?)
      save_question_type_maq_for_vijay(question)
    end

  end

  def save_fib_with_multiple_option(que,opt1,opt2,opt3)
    #to update the question table attribute "ans_status" to "ans"
    save_ans_status_of_save_for_vijay(que)
    fib_check = /___*/

    if fib_check.match(que.question) and (que.passage_id.nil?)
      save_question_type_fib_for_vijay(que)
    end

    if !opt1.nil?
      answer = Answer.new
      answer.answer = opt1
      answer.question_id = que.id
      answer.status = "correct"
      answer.save
    end

    if !opt2.nil?
      answer.update_attribute(:answer,opt1 + ","+ opt2)
    end

    if !opt3.nil?
      answer.update_attribute(:answer,opt1 + ","+opt2 + ","+ opt3)
    end
  end




  def save_sa_tff(que,ans)
    #to update the question table attribute "ans_status" to "ans"
    save_ans_status_of_save_for_vijay(que)
    fib_check = /___*/

    if fib_check.match(que.question) and (que.passage_id.nil?)
      save_question_type_fib_for_vijay(que)
    elsif  (que.passage_id.nil?)
      save_question_type_sa_for_vijay(que)
    end

    answer = Answer.new
    answer.answer = ans[0]
    answer.question_id = que.id
    answer.status = "correct"
    answer.save
  end

  def image_parser(dir_id)
    #this parser goes to the directory where the images are getting saved and take each file and delete
    #the ". , .." files of the directory.
    image_files = Array.new
    #Giving the path of the directory where the images being saved.
    d = Dir.new("/home/satsahib/office/text/app/assets/images/my_images/#{dir_id}/")
    d.each { |file|
      image_files << file
    }
    image_files.delete(".")
    image_files.delete("..")
    return image_files
  end

  def topic_parser(opt)

    #16th march written match data for Topic:
    #1st feb 2012 Matching the topic  pattern and storing it in the topics table
    deleted_topic = opt.slice!("Topic: ")
    deleted_topic = opt.slice!("Topic:")
    deleted_topic = opt.slice!("topic:")
    deleted_topic = opt.slice!("topic :")
    deleted_topic = opt.slice!("Topic : ")
    deleted_topic1 = opt.strip
    if deleted_topic1.empty?
      @topic = Topic.new
      @topic.topic = "Unknown"
      @topic.save
    else
      topic_parser_save_vijay(deleted_topic1)
    end

  end



  def marks_parser(opt)
    deleted_marks = opt.slice!("Marks: ")
    deleted_marks = opt.slice!("marks:")
    deleted_marks = opt.slice!("Marks : ")
    deleted_marks = opt.slice!("marks :")
    deleted_marks1 = opt.strip
    @marks_tag = deleted_marks1.split(',')
  end

  def tag_parser(opt)
    #this parser gets the parses the tags which are given
    # by the user for difficulty, positive_id, negative_id
    deleted_tag = opt.slice!("Tags: ")
    deleted_tag = opt.slice!("tags:")
    deleted_tag = opt.slice!("Tags : ")
    deleted_tag = opt.slice!("tags :")
    deleted_tag1 = opt.strip
    deleted_tag2 = deleted_tag1.split(',')
    difficulty = deleted_tag2[0]
    positive_id = deleted_tag2[1]
    negative_id = deleted_tag2[2]
    tag_parser_save_vijay(difficulty, positive_id, negative_id)
  end

  def question_bank_parser(opt)
    deleted_question_bank = opt.slice!("Question-bank:")
    deleted_question_bank = opt.slice!("Question-Bank:")
    deleted_question_bank = opt.slice!("question-bank:")
    question_bank_name = opt.strip
    question_bank_parser_save_vijay(question_bank_name)
  end

  def passage_parser(opt)
    @recent_pattern=""
    @recent_pattern_passage=""
    passage_parser_save_vijay(opt)
  end

  def  subtopic_parser(opt)
    #1st feb 2012 Matching the sub_topic pattern  and storing it in the subtopics table
    deleted_subtopic = opt.slice!("Sub-Topic: ")
    deleted_subtopic = opt.slice!("Sub-topic: ")
    deleted_subtopic = opt.slice!("sub-Topic: ")
    deleted_subtopic = opt.slice!("sub-topic: ")
    deleted_subtopic = opt.slice!("Sub-Topic : ")
    deleted_subtopic = opt.slice!("Sub-topic : ")
    deleted_subtopic = opt.slice!("sub-Topic : ")
    deleted_subtopic = opt.slice!("sub-topic : ")
    deleted_subtopic1 = opt.strip
    subtopic_parser_save_vijay(deleted_subtopic1)
  end

  def option_parser(opt)
    @recent_pattern=""
    @recent_pattern_option=""
    @answer_copy=""
    #matching the question pattern
    option_parser_save_vijay(opt)
  end

  def question_parser(opt)
    delete_question_part1 = /\{?\[?\(?\:?[Q0-9-\*#\.\t]+[\)\]\/\.\}:][ \t]*/
    delete_question_part2 = /\{?\[?\(?\:?[Q]+[\s]+[0-9-\*#\.\t]+[\)\]\/\.\}:]+[ \t]*/
    delete_question_part3 = /\{?\[?\(?\:?[Q0-9]+[\s]+[\)\]\/\.\}:]+[ \t]*/
    @recent_pattern = ""
    @recent_question_pattern=""
    #matching the answer pattern
    #Now that we hit an option pattern, what ever we have read till now is a question and so save it in question table.
    #This part is for deleting the Q1... part of the Question.....
    if  delete_question_part1.match(opt)
      res = delete_question_part1.match(opt)[0]
      opt.slice!(res)
      question_parser_save_vijay(opt)
    end

    if delete_question_part2.match(opt)
      res = delete_question_part2.match(opt)[0]
      opt.slice!(res)
      question_parser_save_vijay(opt)
    end

    if  delete_question_part3.match(opt)
      res = delete_question_part3.match(opt)[0]
      opt.slice!(res)
      question_parser_save_vijay(opt)
    end
    @recent_que = "1"
    @recent_pattern = "q"
    @recent_question_pattern = @question.question
  end

  def correct_pattern_parser(opt)
    @deleted_answer=""
    @deleted_answer = opt.slice!("Ans: ")
    @deleted_answer = opt.slice!("Answer: ")
    @deleted_answer = opt.slice!("Ans : ")
    @deleted_answer = opt.slice!("Ans :")
    @deleted_answer = opt.slice!("Answer : ")
    @deleted_answer = opt.slice!("Answer :")
    @deleted_answer1 = opt
    @to_answer = @deleted_answer1.split(',')
    @to_answer1 = @to_answer[0]
    @to_answer2 = @to_answer[1]
    @to_answer3 = @to_answer[2]
    @to_answer4 = @to_answer[3]
    @to_answer5 = @to_answer[4]
    if @to_answer.count == 1 and @to_answer[0].strip.length > 1
      save_sa_tff(@question,@to_answer)
    elsif @to_answer.count <= 3 and @to_answer[0].strip.length > 1
      save_fib_with_multiple_option(@question,@to_answer1,@to_answer2,@to_answer3)
    else
      tokenize_option(@question,@to_answer1,@to_answer2,@to_answer3,@to_answer4,@to_answer5)
    end
  end

  def direction_parser(opt)
    @recent_pattern = ""
    @recent_pattern_multi_direction = ""
    @recent_pattern_single_direction = ""
    direction_pattern1 = /([0-9]*-[0-9]*)/
    @deleted_direction = opt.slice!("Directions: ")
    @deleted_direction = opt.slice!("directions:")
    @deleted_direction = opt.slice!("direction:")
    @deleted_direction = opt.slice!("Direction:")
    @deleted_direction = opt.slice!("Direction :")
    @deleted_direction = opt.slice!("direction :")
    @deleted_direction = opt.slice!("Directions :")
    @deleted_direction = opt.slice!("directions :")
    @direction = opt.strip
    #trying to write the code for all kind of directions
    if  direction_pattern1.match(@direction)
      res = direction_pattern1.match(@direction)[0]
      res1 = res.split('-')
      res2 = res1[1].to_i-res1[0].to_i
      @direction_diff = res2 + 1
      @direction_multi = @direction
      @recent_pattern_multi_direction = @direction_multi
      @m_d = "t"
      @recent_pattern="md"
    else
      @m_d = "f"
      @direction_single = @direction
      @recent_pattern_single_direction = @direction_single
      @recent_pattern = "sd"
    end
  end

  def parser_image(opt,dir_id)
    #this parser is paring down the image.
    #finally fixed on 12th march 2012 after working down for a month.
    path_image = "/assets/my_images/#{dir_id}/"
    array_for_getting_name_of_images = Array.new
    array_for_getting_name_of_images = image_parser(dir_id)
    array_for_getting_name_of_images = array_for_getting_name_of_images.sort
    @image = Image.new
    @image.name = array_for_getting_name_of_images[@cfi]
    @image.path = path_image + @image.name
    if (@answer.nil? or @answer.blank?) and (!@question.nil? or !@question.blank?)
      @image.question_id = @question.id
      @image.answer_id = 0
      @image.save
    else
      if @question.id == @answer.question_id
        @image.question_id = 0
        @image.answer_id = @answer.id
        @image.save
      else
        @image.question_id = @question.id
        @image.answer_id = 0
        @image.save
      end
    end
    @cfi = @cfi+1
  end

  def ans_check
    @question = Question.find_by_ans_status("no_ans")
  end

  #VIJAY METHODS

  def save_sd_for_vijay()
    @question.update_attribute(:direction,@recent_pattern_single_direction)
  end

  def save_md_for_vijay()
    @question.update_attribute(:direction,@recent_pattern_multi_direction)
  end

  def save_multi_direction_of_passage_and_question_type_for_vijay()
    @question.update_attribute(:direction,@direction_multi)
    @question.update_attribute(:passage_id,@passage.id)
    @question.update_attribute(:question_type, "PTQ")
  end

  def save_multi_direction_for_vijay()
    @question.update_attribute(:direction,@direction_multi)
  end

  def save_single_direction_for_vijay()
    @question.update_attribute(:direction,@direction_single)
  end

  def save_no_direction_for_vijay()
    @question.update_attribute(:direction,"")
  end

  def save_concat_question_for_vijay()
    @question.update_attribute(:question,@concat_question)
  end

  def save_concat_answer_for_vijay()
    @answer.update_attribute(:answer, @recent_pattern_option)
  end

  def save_concat_passage_for_vijay()
    @passage.update_attribute(:passage, @recent_pattern_passage)
  end

  def save_question_type_maq_for_vijay(question)
    question.update_attribute(:question_type, "MAQ")
  end

  def save_question_type_mcq_for_vijay(question)
    question.update_attribute(:question_type, "MCQ")
  end

  def save_status_correct_for_option_vijay(ans)
    ans.update_attribute(:status, "correct")
  end

  def save_ans_status_of_save_for_vijay(que)
    que.update_attribute(:ans_status, "ans")
  end

  def save_question_type_fib_for_vijay(que)
    que.update_attribute(:question_type, "FIB")
  end

  def save_question_type_sa_for_vijay(que)
    que.update_attribute(:question_type, "SA")
  end

  def tag_parser_save_vijay(difficulty, positive_id, negative_id)
    @question.difficulty_id = difficulty
    @question.positive_id = positive_id
    @question.negative_id = negative_id
    @question.save
  end

  def save_ans_status_to_ans_for_vijay(question)
    question.update_attribute(:ans_status, "ans")
  end

  def topic_parser_save_vijay(topic)
    @topic = Topic.new
    @topic.topic = topic
    @topic.save
  end

  def question_bank_parser_save_vijay(question_bank_name)
    @question_bank = QuestionBank.new
    @question_bank.name = question_bank_name
    @question_bank.save
  end

  def passage_parser_save_vijay(opt)
    @passage = Passage.new
    @passage.passage = opt
    @passage.save
    @recent_pattern_passage=opt
    @recent_pattern = "p"
    @is_passage_question = true
  end

  def subtopic_parser_save_vijay(subtopic)
    @subtopic = SubTopic.new
    @subtopic.subtopic = subtopic
    @subtopic.topic_id = @topic.id
    @subtopic.save
  end

  def option_parser_save_vijay(opt)
    @answer = Answer.new
    @answer.answer = opt
    @answer.question_id = @question.id
    @answer_copy = @answer.answer
    @answer.save
    @recent_pattern = "a"
    @recent_pattern_option = @answer.answer
  end

  def question_parser_save_vijay(opt)
    @question = Question.new
    @question.question = opt
    @question.topic_id = @topic.id
    @question.sub_topic_id = @subtopic.id
    @question.positive_id = @marks_tag[0]
    @question.negative_id = @marks_tag[1]
    @question.save
  end
  
  def index
    @questions = Question.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @questions }
    end
  end

  # GET /questions/1
  # GET /questions/1.json
  def show
    @question = Question.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @question }
    end
  end

  # GET /questions/new
  # GET /questions/new.json
  def new
    @question = Question.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @question }
    end
  end

  # GET /questions/1/edit
  def edit
    @question = Question.find(params[:id])
  end

  # POST /questions
  # POST /questions.json
  def create
    @question = Question.new(params[:question])

    respond_to do |format|
      if @question.save
        format.html { redirect_to @question, notice: 'Question was successfully created.' }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
    @question = Question.find(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:question])
        format.html { redirect_to @question, notice: 'Question was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    @question = Question.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to questions_url }
      format.json { head :no_content }
    end
  end

  def save_questions
    require 'fileutils'
    tmp = params[:question].tempfile
    file = File.join("/home/satsahib/office/text/public", params[:question].original_filename)
    FileUtils.cp tmp.path, file
    @path = file
    @dir_id = params[:surupa_id]
    pdf_file = params[:question].original_filename.split('.')[0] + ".pdf"
    @pdf_path = File.join("/home/satsahib/office/text/public",pdf_file)
    txt_file = params[:question].original_filename.split('.')[0] + ".txt"
    @txt_path = File.join("/home/satsahib/office/text/public",txt_file)
  end
  
  def destroy_all
    @question = Question.find(:all)
    @question.each do |q|
      q.destroy
    end
    @answer = Answer.find(:all)
    @answer.each do |a|
      a.destroy
    end

    @image = Image.find(:all)
    @image.each do |q|
      q.destroy
    end

    @topic = Topic.find(:all)
    @topic.each do |q|
      q.destroy
    end
    @subtopic = SubTopic.find(:all)
    @subtopic.each do |q|
      q.destroy
    end
    @passage = Passage.find(:all)
    @passage.each do |q|
      q.destroy
    end
      redirect_to :action => :index
  end

  def preview
    @questions = Question.all
  end
end
