# -*- coding: utf-8 -*-

Plugin.create(:oasiz_list_reader) do

    @mikutter_start_time = nil

    # config に設定項目を追加
    settings("リスト読み上げ") do
        settings("基本設定") do
            multi '読み上げ対象リスト(@username/listname)', :oasiz_list_reader_list_names
            boolean '読み上げ有効', :oasiz_list_reader_is_enable
        end
    end

    # mikutter 起動時間記録
    on_boot do |service|
        UserConfig[:oasiz_list_reader_is_enable] ||= true
        @mikutter_start_time = Time.now
    end

    # リスト更新イベント
    on_list_update do |list, messages|
        # 音声読み上げが OFF であれば何もしない
        unless UserConfig[:oasiz_list_reader_is_enable] then
            return
        end

        # 読み上げ対象リスト以外であれば無視
        unless UserConfig[:oasiz_list_reader_list_names].include?("@#{list.user}/#{list[:name]}") then
            return
        end

        for message in messages do
            # mikutter 起動以前のツイートは無視
            if message[:created] < @mikutter_start_time then
                next
            end

            # メッセージリビルドプラグインにリビルド依頼
            read_text = Plugin.filtering(:rebuild_message, message)[0].body

            # リビルド後のテキストを読み上げ依頼
            Plugin.filtering(:voicetext_read, read_text)
        end
    end
end
