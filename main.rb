# encoding:utf-8

require 'rest-client'
require 'nokogiri'
require 'mysql2'
require 'json'
require 'pp'

def hdu_get(pid)
    baseurl = "http://acm.hdu.edu.cn/showproblem.php?pid=#{pid.to_s}"

    begin 
        response = RestClient.get baseurl
    rescue Exception => e
        p "connect error + #{pid}"
    end

    begin 
        body = response.body.force_encoding("gbk").encode!("utf-8")
    rescue
        p "encoding error #{pid}"
    end
    
    doc = Nokogiri::HTML(body)

    # find all types of the website
    result = Hash.new
    doc.search('//div[@class="panel_title"]').each do |row|
        result["#{row.children.text}"] = nil
    end

    value_tmp = Array.new   
    doc.search('//div[@class="panel_content"]').each do |row|
        value_tmp <<  row.children.to_s
    end

    result.each do |index, value|
        result[index] = value_tmp.delete(value_tmp.first)
    end

    result['title'] = doc.search('//h1').children.text

    limit_tmp = doc.search('//font/b/span').children.text
    limit_tmp = limit_tmp.split(" ")
    result['Timelimit'] = "#{limit_tmp[2]} MS"
    result['Memorylimit'] = "#{limit_tmp[6]} K"

    begin
        result = result.to_json
    rescue
        p "to_json method error #{pid}"
    end
    
    io = File.open("./problems/#{pid}.json", "w")
    io << result
    io.close
    
end

def hdu_pagenum_max
    baseurl = "http://acm.hdu.edu.cn/listproblem.php?vol=1"
    response = RestClient.get baseurl
    doc = Nokogiri::HTML(response.body)

    result = Array.new
    doc.search('//font/a').each { |row| result << row.children.text }

    result[-1].to_i
end

# Todo
def hdu_pid_max(page) 
    baseurl = "http://acm.hdu.edu.cn/listproblem.php?vol=#{page.to_s}"
    response = RestClient.get baseurl
    doc = Nokogiri::HTML(response.body)

    result = Array.new
    io = File.open("test.html", "w")
    doc.search('//table/tr[5]/td/table/.').each do |row|
        io << row
    end
    io.close
end

def thread(max_num)
    offset = max_num / 1000
    thread = Array.new
    1.upto(offset) do |n|
        temp = Thread.new{
            first_num = 1000 * n
            if max_num - first_num >= 1000
                first_num.upto(first_num + 999) do |pid|
                    hdu_get(pid)
                end
            else
                first_num.upto(max_num) do |pid|
                    hdu_get(pid)
                end
            end
        }
        thread << temp
    end

    thread.each { |n| n.join }
end


thread(6022)

