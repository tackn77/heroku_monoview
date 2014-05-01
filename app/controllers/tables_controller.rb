class TablesController < ApplicationController

  # 時刻表取得部分
  # データベースへ逐次保存
  def new
    today = Date.today
    
    require 'nokogiri'
    require 'open-uri'
    require 'nkf'

    re = Regexp.new("[^>]+/(HA|KA)([0-9]+)\\.pdf")
    doc = Nokogiri::HTML

    doc = Nokogiri::HTML(open('http://chiba-monorail.co.jp/index.php/info-timetable/urban-monochan/'))
    
    month = 0
    doc.xpath("//table[@class='mono-time']//td/a").each do |i|
      /((1?[0-9]?)\/)?([0-9]+)/ =~ NKF.nkf('-m0Z1 -w', i.text)
      if month == 0 && $2==nil
        month = 0
      elsif $2==nil 
        month = month
      else
        month = $2
      end
      day = $3
      
      train = 0
      re =~ i.attribute("href").value
      type = $1
      if type=="KA" then holiday=true else holiday=false end
      tableNo = $2 

      table = Table.new
      table.month =month
      table.day=day
      table.train=train
      table.holiday=holiday
      table.table=tableNo
      
      table.save
    end

    month = 0
    doc.xpath("//table[@class='urban-time']//tr//a").each do |node|
      trainNo =  NKF.nkf('-m0Z1 -w', node.text)
      re =~  node.attribute("href").value
      type = NKF.nkf('-m0Z1 -w', $1)
      if type=="KA" then holiday=true else holiday=false end
      tableNo = NKF.nkf('-m0Z1 -w', $2)

      count = node.xpath("count(ancestor::td/preceding-sibling::td)") 
      day =  node.xpath("ancestor::tr[position()=1]/preceding-sibling::tr[position()=1]/td[position()=" + ((count-1) / 4 +1).to_i.to_s+ "]/text()") 

      /((1?[0-9])\/)?([0-9]+)[^\/]+/ =~ NKF.nkf('-m0Z1 -w',day.to_s)
      if month == 0 && $2==nil
        month = 0
      elsif $2==nil 
        month = month
      else
        month = $2
      end
      
      table = Table.new
      table.month =month
      table.day=$3
      table.train=trainNo
      table.holiday=holiday
      table.table=tableNo
 
      table.save
    end
    
    #0を入れておいた仮月数を正式な月にアップデート    
    if(month=="1") 
      pre_month = 12
    else
      pre_month =month.to_i-1
    end
    tables = Table.where(:month=>"0")
    tables.update_all(:month=>pre_month)
  end   


  def index
    @tables = Table.all
  end



  
end
