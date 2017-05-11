# encoding:utf-8

require 'rest-client'
require 'reverse_markdown'
require 'nokogiri'
require 'json'
require 'pp'

def hdu_get(pid)
    baseurl = "http://acm.hdu.edu.cn/showproblem.php?pid=#{pid.to_s}"

    begin
        response = RestClient.get baseurl
    rescue Exception => e
        p "connect error + #{pid}"
        retry
    end

    begin
        body = response.body.force_encoding("gbk").encode!("utf-8")
    rescue
        p "encoding error #{pid}"
        return nil
    end

    doc = Nokogiri::HTML(body)
    host = "http://acm.hdu.edu.cn"
    # special
    doc.search('//a').each do |row|
        row.attributes['href'].value = host + row.attributes['href'].value if row.attributes['href'] != nil
    end

    host = "http://acm.hdu.edu.cn/data"
    doc.search('//img').each do |row|
        temp = host + row.attributes['src'].value.split("data")[-1]
        row.attributes['src'].value = temp if row.attributes['src'] != nil
    end

    # find all types of the website
    result = Hash.new
    doc.search('//div[@class="panel_title"]').each do |row|
        result["#{row.children.text}"] = nil
    end

    value_tmp = Array.new
    doc.search('//div[@class="panel_content"]').each do |row|
        #p row.children.to_s
        temp = row.children.to_s
        #temp = row.children.to_s.gsub('<pre>', '').gsub('</pre>', '').gsub("\u00A0", "").strip
        value_tmp << temp.gsub("\u00A0", " ")
    end

    result.each do |index, value|
        result[index] = value_tmp.delete_at(0)
    end

    result.each do |index, value|
        result[index] = ReverseMarkdown.convert(value, unknown_tags: :bypass).strip if index != "Sample Input" && index != "Sample Output"
    end

    result["Sample Input"] = Nokogiri::HTML.parse(result["Sample Input"]).text
    result["Sample Output"] = Nokogiri::HTML.parse(result["Sample Output"]).text

    result['title'] = ReverseMarkdown.convert(doc.search('//h1').children.text).strip

    begin
        limit_tmp = doc.search('//font/b/span').children.text
        limit_tmp = limit_tmp.split(" ")
        result['Timelimit'] = "#{limit_tmp[2].split("/")[-1]}"
        result['Memorylimit'] = "#{limit_tmp[6].split("/")[-1]}"
    rescue
        p "#{pid} is nil"
        return nil
    end

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

def hdu_pid_max(page)
    baseurl = "http://acm.hdu.edu.cn/listproblem.php?vol=#{page.to_s}"
    response = RestClient.get baseurl
    doc = Nokogiri::HTML(response.body)

    result = 1000
    doc.search('//table/tr[5]/td/table/script').each do |row|
        result = row.children.to_s.split(";")[-1].split(",")[1]
    end

    return result if result != 1000
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

#hdu_get(1065)
thread(hdu_pid_max(hdu_pagenum_max).to_i)
