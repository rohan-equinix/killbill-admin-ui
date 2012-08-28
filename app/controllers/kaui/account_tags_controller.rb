class Kaui::AccountTagsController < Kaui::EngineController

  def show
    account_id = params[:id]

    if account_id.present?
      begin
        tags = Kaui::KillbillHelper::get_tags_for_account(account_id)
      rescue => e
        flash[:error] = "Error while getting tags: #{as_string(e)}"

      end
    else
      flash[:error] = "No account id given"
    end
  end

  def edit
    @account_id = params[:account_id]
    begin
      @available_tags = Kaui::TagDefinition.all_for_account.sort
      @account = Kaui::KillbillHelper::get_account(@account_id)
      @tag_names = Kaui::KillbillHelper::get_tags_for_account(@account.account_id).map { |tag| tag.tag_definition_name }
    rescue => e
      flash[:error] = "Error while editing tags: #{as_string(e)}"
    end
  end

  def update
    begin
      current_tags = Kaui::KillbillHelper::get_tags_for_account(params[:account_id]).map { |tag| tag.tag_definition_id }

      new_tags = []
      params.each do |tag, tag_name|
        tag_info = tag.split('_')
        next if tag_info.size != 2 or tag_info[0] != 'tag'
        new_tags << tag_info[1]
      end

      # Find tags to remove
      tags_to_remove = []
      current_tags.each do |current_tag_definition_id|
        tags_to_remove << current_tag_definition_id unless new_tags.include?(current_tag_definition_id)
      end

      # Find tags to add
      tags_to_add = []
      new_tags.each do |new_tag_definition_id|
        tags_to_add << new_tag_definition_id unless current_tags.include?(new_tag_definition_id)
      end

      Kaui::KillbillHelper::remove_tags_for_account(params[:account_id], tags_to_remove)
      Kaui::KillbillHelper::add_tags_for_account(params[:account_id], tags_to_add)
    rescue => e
      flash[:error] = "Error while updating tags: #{as_string(e)}"
    end
    redirect_to kaui_engine.account_path(params[:account_id])
  end

end
