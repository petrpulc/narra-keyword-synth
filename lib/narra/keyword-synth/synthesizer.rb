#
# Copyright (C) 2014 CAS / FAMU
#
# This file is part of Narra Core.
#
# Narra Core is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Narra Core is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Narra Core. If not, see <http://www.gnu.org/licenses/>.
#
# Authors: Petr Pulc <petrpulc@gmail.com>
#

require 'narra/spi'
require 'narra/tools'

module Narra
  module KeywordSynth
    class Synthesizer < Narra::SPI::Synthesizer
    
      # Default values
      @identifier = :keywordsynth
      @title = 'Keyword Synthesizer'
      @description = 'Narra Synthesizer based on item keywords'

      def self.valid?(project_to_check)
        true
      end
      
      def value_keywords(metaitems)
        keywords = Hash.new(0.0)
        
        metaitems.each do |meta|
          words = meta.value.split(',')
          words.each_with_index do |w, i|
            keywords[w.strip] += 1/Float(i)
          end
        end
        
        keywords
      end
      
      def keyword_weight(item1, item2, fields)
        kw1 = value_keywords(Narra::MetaItem.where(item: item1).any_in(name: fields))
        kw2 = value_keywords(Narra::MetaItem.where(item: item2).any_in(name: fields))
        
        #sum up multiplier of individual keyword weights
        weight = 0.0
        kw1.each do |w, val|
          weight += val * kw2[w]
        end
      end

      def synthesize(options = {})
        #get list of fields to search in, fallback to ['keywords']
        fields = options[:fields]
        fields ||= ['keywords']
        
        #store fully processed item ids, so we will not count distance twice
        processed_ids = []
        
        @project.items.each do |item1|
          @project.items.each do |item2|
            #skip lower triangle and diagonal
            next if processed_ids.include? item2._id.to_s
            next if item1 == item2
            
            #count keyword distance
            weight = keyword_weight(item1, item2, fields)
            add_junction([item1, item2], weight: weight, synthesizer: @identifier) if weight > 0
          end
          processed_ids << item1._id.to_s
        end
      end

      def self.listeners
        #TODO redefine in future
        []
      end
    end
  end
end
