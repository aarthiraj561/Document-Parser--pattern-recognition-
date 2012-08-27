require 'test_helper'

class SubTopicsControllerTest < ActionController::TestCase
  setup do
    @sub_topic = sub_topics(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sub_topics)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sub_topic" do
    assert_difference('SubTopic.count') do
      post :create, sub_topic: @sub_topic.attributes
    end

    assert_redirected_to sub_topic_path(assigns(:sub_topic))
  end

  test "should show sub_topic" do
    get :show, id: @sub_topic
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sub_topic
    assert_response :success
  end

  test "should update sub_topic" do
    put :update, id: @sub_topic, sub_topic: @sub_topic.attributes
    assert_redirected_to sub_topic_path(assigns(:sub_topic))
  end

  test "should destroy sub_topic" do
    assert_difference('SubTopic.count', -1) do
      delete :destroy, id: @sub_topic
    end

    assert_redirected_to sub_topics_path
  end
end
