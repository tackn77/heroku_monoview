class TablesController < ApplicationController

  # 時刻表取得部分
  # データベースへ逐次保存
  def new
    #今日の取得
    today = Date.today
    #DBのデータをいったん全削除
    Table.all.destroy_all

    # 日付情報取得する正規表現
    re_date = Regexp.new("((1?[0-9]?)\/)?([0-9]+)")
    #リンクされているPDFアンカーから情報を取得する正規表現
    re_pdf = Regexp.new("[^>]+/(HA|KA)([0-9]+)\\.pdf")
    
    #nokogiriを使った運行情報の取得処理
    require 'nokogiri'
    require 'open-uri'
    require 'nkf'

    #モノレール運行情報を取得
    doc = Nokogiri::HTML(open('http://chiba-monorail.co.jp/index.php/info-timetable/urban-monochan/'))

    #月情報が無いので0でとりあえず初期化
    month = 0
    #モノちゃん号のデータ取得
    doc.xpath("//table[@class='mono-time']//td/a").each do |node|
      #日付情報の取得
      re_date =~ NKF.nkf('-m0Z1 -w', node.text)
      if month == 0 && $2==nil
        month = 0
      elsif $2==nil 
        month = month
      else
        month = $2
      end
      day = $3
      
      #モノちゃん号は0号車とする
      train = 0
      
      #ファイル名から情報取得
      re_pdf =~ node.attribute("href").value
      #平日/休日ダイヤ判定
      type = $1
      if type=="KA" then holiday=true else holiday=false end
      #運行ダイヤ取得
      tableNo = $2 

      #DBへ詰め込み
      table = Table.new
      table.month =month
      table.day=day
      table.train=train
      table.holiday=holiday
      table.table=tableNo
      
      table.save
    end

    #月情報が無いので0でとりあえず初期化
    month = 0
    #アーバンフライヤー0形のデータ取得
    doc.xpath("//table[@class='urban-time']//tr//a").each do |node|
      #車両ナンバー取得
      trainNo =  NKF.nkf('-m0Z1 -w', node.text)
      #ファイル名から情報取得
      re_pdf =~  node.attribute("href").value
      #平日/休日ダイヤ判定
      type = NKF.nkf('-m0Z1 -w', $1)
      if type=="KA" then holiday=true else holiday=false end
      #運行ダイヤ取得
      tableNo = NKF.nkf('-m0Z1 -w', $2)
      #日付情報取得
      count = node.xpath("count(ancestor::td/preceding-sibling::td)") 
      day =  node.xpath("ancestor::tr[position()=1]/preceding-sibling::tr[position()=1]/td[position()=" + ((count-1) / 4 +1).to_i.to_s+ "]/text()") 
      #日付情報解析
      re_date =~ NKF.nkf('-m0Z1 -w',day.to_s)
      if month == 0 && $2==nil
        month = 0
      elsif $2==nil 
        month = month
      else
        month = $2
      end
      #DBへ積み込み
      table = Table.new
      table.month =month
      table.day=$3
      table.train=trainNo
      table.holiday=holiday
      table.table=tableNo
 
      table.save
    end
    
    #0を入れておいた仮月数を正式な月にアップデート    
    if(month=="0") 
      beginning_month = today.month
    elsif(month=="1") 
      beginning_month = 12
    else
      beginning_month =month.to_i-1
    end
    tables = Table.where(:month=>"0")
    tables.update_all(:month=>beginning_month)
  end   

  #すべての運行情報を返す
  def index
    @tables = Table.all
  end

 #今日の運行情報を返す 
  def today
    #今日作成のレコードが無かったら取得を実行
    if Table.exists?(:created_at => Date.today.beginning_of_day..Date.today.end_of_day)
      new
    end
    #今日の運行情報を取得
    today = Date.today
    @tables = Table.where(:month=>today.month,:day=>today.day)
    #取得結果をViewへ返す
    respond_to do |format|
      format.html
      format.json{render :json =>@tables}
      format.xml{render :xml =>@tables}
    end
  end
end
