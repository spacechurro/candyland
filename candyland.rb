#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'

require 'json'
require 'pry'

# colors from Kelly’s 22 Colours of Maximum Contrast
# https://gist.github.com/ollieglass/f6ddd781eeae1d24e391265432297538
colors = ['F3C300', '875692', 'F38400', 'A1CAF1', 'BE0032', 'C2B280', '848482', '008856', 'E68FAC', '0067A5', 'F99379', '604E97', 'F6A600', 'B3446C', 'DCD300', '882D17', '8DB600', '654522', 'E25822', '2B3D26']


LIST_NAMES = [
                #"January 2018",
                #"February 2018",
                "March 2018",
                "April 2018",
                "May 2018",
                "June 2018",
                "July 2018",
                "August 2018",
                "September 2018",
                "October 2018",
                "November 2018",
                "December 2018"
]

filename = ARGV[0]
roadmap = JSON.parse(File.read(filename), symbolize_names: true) 
cards = roadmap[:cards]
lists = roadmap[:lists].select { |list| LIST_NAMES.include?(list[:name]) }


relevant_cards = cards.select do |card|
  labels = card[:labels].collect { |label| label[:name] }
  labels.any? { |label| label =~ /^F:/ } && lists.map { |l| l[:id] }.include?(card[:idList]) 
end


# collect list of all feature labels

labels = relevant_cards.collect do |card|
  card[:labels].find { |label| label[:name] =~ /^F:/ }[:name]
end

labels.uniq!

# build board

board = {}

relevant_cards.each do |card|
  list_id = card[:idList]
  label = card[:labels].find { |l| l[:name] =~/^F:/ }

  board[list_id] ||= []
  board[list_id] << "#{card[:name]} (#{label[:name]})"
end

max_list_size = board.values.collect { |list| list.size }.max

board.each do |list_id, cards|
  board[list_id] = cards + [nil] * (max_list_size - cards.size) if cards.size < max_list_size
end

transposed_board = board.values.transpose

# write out html

basename = File.basename(filename, ".*")
File.open("#{basename}.html", 'w') do |f|
  f << "<html>\n"
  f << "<body>\n"
  f << "<table>\n"

  f << "<tr>\n"
  LIST_NAMES.each do |list_name|
    f << "<th>#{list_name}</th>" 
  end
  f << "</tr>\n"

  transposed_board.each_with_index do |row, index|
    f << "<tr>\n"

    row.each do |card|

      if card
        label_in_use = labels.find { |label| card =~ /#{label}/ }
        index = labels.index(label_in_use)
        bgcolor = colors[index]
      else
        bgcolor = "FFFFFF"
      end

      f << "<td bgcolor='##{bgcolor}'>#{card}</td>"
    end

    f << "</tr>\n"
  end

  f << "</table>\n"
  f << "</body>\n"
  f << "</html>\n"
end
