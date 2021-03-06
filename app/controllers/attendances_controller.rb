class AttendancesController < ApplicationController
  include AttendancesHelper
  before_action :set_user, only: [:edit_one_month, :update_one_month, :edit_notice_overtime,
                                  :edit_change_attendance, :edit_attendance_log]
  before_action :set_attendance, only: [:edit_overtime_app, :update_over_app, :update_notice_overtime, :update_change_attendance]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :set_one_month, only: [:edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :superior_user, only: [:edit_overtime_app, :edit_change_attendance]
  before_action :rejection_admin, only: [:show, :edit_one_month]
  
  require 'csv'
  require 'rails/all'
  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  def update
    @attendance = Attendance.find(params[:id])
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        @attendance.update_attributes(updated_started_at: @attendance.started_at)
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil? 
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        @attendance.update_attributes(updated_finished_at: @attendance.finished_at)
        flash[:info] = "お疲れ様でした！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def csv_output
    user = User.find_by(id: current_user)
    @first_day = params[:date].to_date
    @last_day = @first_day.end_of_month
    @attendance = user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    # @attendance = Attendance.joins(:user).where(id: Attendance.where(worked_on: @first_day..@last_day).where(user_id: current_user))
    send_data render_to_string, filename: "attendances.csv", type: :csv
  end
  
  def edit_one_month  
  end
  
  def update_one_month
    ActiveRecord::Base.transaction do
      if attendances_updated_invalid?
        attendances_params.each do |id, item|
          attendance = Attendance.find(id)
          if item[:name].present?
            if attendance.attendance_change_check == true
              attendance.update_attributes!(item)
              attendance.update_attributes!(attendance_change_check: false, confirm: "申請中",
                                            before_started_at: attendance.updated_started_at, before_finished_at: attendance.updated_finished_at)
            else
              attendance.update_attributes!(item)
              attendance.update!(attendance_change_flag: true, confirm: "申請中")
            end
          end
        end
        flash[:success] = "1ヶ月分の勤怠情報を更新しました。</br>※上長が未選択のものは更新されません。".html_safe 
        redirect_to user_url(@user, date: params[:date])
      else
        flash[:danger] = "不正な入力情報がありました、再入力してください。"
        redirect_to user_url(@user, date: params[:date])
      end
    end
  rescue ActiveRecord::RecordInvalid
      flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
      redirect_to attendances_edit_one_month_user_path(@user, date: params[:date])
  end

   # 残業申請のモーダル
  def edit_overtime_app
    @attendances = Attendance.where(id: params[:id], user_id: params[:user_id])
    @today = Date.today
  end
  
  # 残業申請の更新処理
  def update_over_app
    @worktime = @user.designated_work_end_time
    @attendance = Attendance.find(params[:id])
    if overtime_params_updated_invalid?
      if params[:attendance][:name].blank?
        flash[:danger] = "上長が選択されていません。"
        redirect_to @user
      else
        @attendance.update(overtime_params)
        @attendance.update(overtime_confirm: "申請中", overtime_check: false)
        flash[:success] = "残業申請しました。"
        redirect_to @user
      end
    else
      if @attendance.updated_finished_at.blank?
        flash[:danger] = "退社時間が未入力です。"
        redirect_to @user
      elsif ((params[:attendance]["endtime_at(4i)"].to_i < @worktime.hour) &&
              params[:attendance][:tommorow_index] == "false")
        flash[:danger] = "指定勤務終了時間より早い終了予定時間は無効です。"
        redirect_to @user
      else
        flash[:danger] = "申請情報に不正な入力があるため、残業申請できませんでした。"
        redirect_to @user
      end
    end
  end
  
  # 残業申請のお知らせモーダル
  def edit_notice_overtime
    @notice_users = User.where(id: Attendance.where(name: current_user.name).where(overtime_check: false).where.not(endtime_at: nil).select(:user_id)).where.not(id: current_user)
    users(@notice_users)
  end
  
  # 残業申請お知らせの更新
  def update_notice_overtime
    # 前提:form_withのurl引数（@user）はbefore_actionの
    #      set_userによって「上長」のユーザー情報を得る。
    @notice_users = User.where(id: Attendance.where(overtime_check: false).where.not(endtime_at: nil).select(:user_id))
    users(@notice_users)
    if overtime_notice_updated_invalid?
      notice_overtime_params.each do |id, item|
        attendance = Attendance.find(id)
        if params[:attendance][:notice_attendances][id][:overtime_check] == "true"
          attendance.update_attributes(item)
        end
      end
      flash[:success] = "残業申請の変更を通知しました。</br>※変更にチェックがない申請は更新されていません。".html_safe
      redirect_to @user
    else
      flash[:danger] = "残業申請の変更ができませんでした。</br>※変更チェックボックスが選択されません。"
      redirect_to @user
    end
  end
  
  # 勤怠変更申請のお知らせモーダル表示
  def edit_change_attendance
    @att_update_list = Attendance.where.not(updated_started_at: nil).or(Attendance.where.not(updated_finished_at: nil)).where(name: @user.name)
    @users = User.where(id: Attendance.where(name: current_user.name).where(attendance_change_check: false).where(attendance_change_flag: true).where.not(updated_started_at: nil).select(:user_id)).where.not(id: current_user)
    @att_update_list.each do |att_up|
      @att_up = att_up
    end
  end

   # 勤怠変更申請お知らせモーダルの更新
  def update_change_attendance
    @att_update_list = Attendance.where.not(updated_started_at: nil).or(Attendance.where.not(updated_finished_at: nil)).where(name: current_user.name)
    if change_attendance_updated_invalid?
      change_attendance_params.each do |id, item|
        attendance = Attendance.find(id)
        if params[:attendance][:updated_attendances][id][:attendance_change_check] == "true"
          attendance.update_attributes(item)
        end
      end
      flash[:success] = "勤怠変更申請のお知らせを変更しました。</br>※変更にチェックがないものは更新されません。"
      redirect_to @user
    else
      flash[:danger] = "勤怠変更申請の変更ができませんでした。</br>※変更チェックボックスが選択されていません。"
      redirect_to @user
    end
  end
  
  # 勤怠修正ログ
  def edit_attendance_log
    @updated_attendance_list = Attendance.where.not(updated_started_at: nil).or(Attendance.where.not(updated_finished_at: nil)).where(user_id: current_user)
  end

  
  
  private
    def attendances_params
      params.require(:user).permit(:attendance_change_flag, attendances: [:updated_started_at, :updated_finished_at, :tommorow_index, :note, :name])[:attendances]
    end
    
    def overtime_params
      params.require(:attendance).permit(:endtime_at, :tommorow_index, :overtime_memo, :name)
    end
    
     def notice_overtime_params
      params.require(:attendance).permit(notice_attendances: [:overtime_confirm, :overtime_check])[:notice_attendances]
     end
     
     def change_attendance_params
      params.require(:attendance).permit(updated_attendances: [:note, :confirm, :attendance_change_check])[:updated_attendances]
     end
     
     def updated_time_params
       params.require(:user).permit(attendances: [:updated_started_at, :updated_finished_at, :tommorow_index, :note, :name])[:attendances]
     end
    
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
      flash[:danger] = "編集権限がありません。"
      redirect_to(root_url)
      end
    end
end
