class SubTopicsController < ApplicationController
  # GET /sub_topics
  # GET /sub_topics.json
  def index
    @sub_topics = SubTopic.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sub_topics }
    end
  end

  # GET /sub_topics/1
  # GET /sub_topics/1.json
  def show
    @sub_topic = SubTopic.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sub_topic }
    end
  end

  # GET /sub_topics/new
  # GET /sub_topics/new.json
  def new
    @sub_topic = SubTopic.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sub_topic }
    end
  end

  # GET /sub_topics/1/edit
  def edit
    @sub_topic = SubTopic.find(params[:id])
  end

  # POST /sub_topics
  # POST /sub_topics.json
  def create
    @sub_topic = SubTopic.new(params[:sub_topic])

    respond_to do |format|
      if @sub_topic.save
        format.html { redirect_to @sub_topic, notice: 'Sub topic was successfully created.' }
        format.json { render json: @sub_topic, status: :created, location: @sub_topic }
      else
        format.html { render action: "new" }
        format.json { render json: @sub_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sub_topics/1
  # PUT /sub_topics/1.json
  def update
    @sub_topic = SubTopic.find(params[:id])

    respond_to do |format|
      if @sub_topic.update_attributes(params[:sub_topic])
        format.html { redirect_to @sub_topic, notice: 'Sub topic was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sub_topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sub_topics/1
  # DELETE /sub_topics/1.json
  def destroy
    @sub_topic = SubTopic.find(params[:id])
    @sub_topic.destroy

    respond_to do |format|
      format.html { redirect_to sub_topics_url }
      format.json { head :no_content }
    end
  end
end
