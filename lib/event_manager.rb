require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'



def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    
    begin
        civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']).officials
    rescue
        "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
    end
end

def clean_phone_number(phone_number)
    phone_number.gsub!(/[^0-9]/, '')
    
    if phone_number.to_s.length < 10 
        "0000000000"
    elsif phone_number.to_s.length == 11 && phone_number.to_s[0] == "1"
        phone_number[1..-1]
    elsif phone_number.to_s.length == 11 && phone_number.to_s[0] != "1"
        "0000000000"
    elsif phone_number.to_s.length > 11
        "0000000000"
    else
        phone_number
    end

end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def get_reg_hour(reg_date)
    DateTime.strptime(reg_date, '%m/%d/%Y %H:%M').strftime('%H')
end

def count_reg_hours(reg_hour, hours_hash)
    tmp = hours_hash[reg_hour]
    hours_hash[reg_hour] = tmp + 1
    hours_hash
end

def hours_with_most_reg(hours_hash)
    hours_with_most_reg_array = [] 
    hours_hash.each { |k,v| hours_with_most_reg_array << k if v == hours_hash.values.max }
    hours_with_most_reg_array
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter


reg_hour_hash = Hash.new(0)

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phone_number = clean_phone_number(row[:homephone])
    reg_hour = get_reg_hour(row[:regdate])
    reg_hour_hash = count_reg_hours(reg_hour, reg_hour_hash)
    legislators = legislators_by_zipcode(zipcode)


    # puts phone_number
    # form_letter = erb_template.result(binding)
    # save_thank_you_letter(id, form_letter)
end


# hours_with_most_reg_array = hours_with_most_reg(reg_hour_hash)
# puts hours_with_most_reg_array
