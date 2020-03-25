class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update, :edit_basic_info]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :set_one_month, only: :show
  before_action :admin_or_correct_user, only: :show
  before_action :superior_user, only: :show

  def index
    @users = User.all
  end
 
  def import
    unless params[:file].blank?
      # 保存と結果のメッセージを取得して表示
      User.import(params[:file])
      flash[:info] = "CSVファイルをインポートしました。"
    else
      flash[:danger] = "読み込むCSVファイルをセットしてください"
    end
      redirect_to users_path
  end
  
  def index_attendance
    @users = User.all.includes(:attendances)
  end
    
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to users_url
    else
      render :edit      
    end
  end
  
  def destroy
    @user.destroy
    flash[:success] = "User deleted.."
    redirect_to users_url
  end

  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
    # 残業申請のお知らせ合計
    @notice_users = User.where(id: Attendance.where.not(endtime_at: nil).select(:user_id)).where.not(id: current_user)
    @notice_users.each do |user|
      @attendances_list = Attendance.where(user_id: user.id).where.not(endtime_at: nil)
      @endtime_notice_sum = @attendances_list.count
    end
    # 勤怠変更申請のお知らせ合計
    @att_update_list = Attendance.where(name: current_user.name).where.not(updated_started_at: nil) || where.not(updated_finished_at: nil)
    @att_update_sum = @att_update_list.count
    # 所属長承認申請（今のユーザーに申請分）の合計
    @approval_list = Approval.where(superior_id: current_user)
    @approval_sum = @approval_list.count
    @current_approval = Approval.find_by(user_id: @user)
  end
  
  def admin_or_correct_user
    unless current_user?(@user) || current_user.admin? || current_user.superior?
      flash[:danger] = "ログインしてください。"
      redirect_to(root_url)
    end
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password,
                                  :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    def basic_params
      params.require(:user).permit(:basic_time, :work_time)
    end
end