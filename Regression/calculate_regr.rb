#See section 4.5 in the paper. This script reads the tagged test sets and calculates the values of the factors which we consider potential predictors of the tag accuracy. It reads the files from the RegrInput folder and generates the files in the RegrOutput folder, which must then be fed to the R script for running the regression analysis itself.

#a function to calculate the entropy from a given hash
def entropy(hash) 
    entr = 0.0
    total = 0.0
    hash.each_value do |v|
        total += v
    end
    hash.each_value do |v|
        if v > 0
            entr += (v/total)*Math.log2(v/total)
        end
    end
    
    entr = -entr#/Math.log2(normalizer) 
    
    return entr
end

filelist = Dir.children("RegrInput") #listing all the files in the folder which contains the tagged test sets
taggerlist = ["1Bert", "2Flair", "3Stanza", "4Marmot", "5Hunpos"]

filelist.each do |filename|
    STDERR.puts filename
    o = File.open("RegrOutput\\#{filename.split(".")[0]}_regr.tsv","w:utf-8") #create the output file for the given corpus
    o.puts "Tag\t#{taggerlist.join("\t")}\tFreq\tttr\tentr_token\tentr_ending"
    
    #create the variables 
    tagcorrect = Hash.new{|hash, key| hash[key] = Hash.new(0.0)}
    tagtotal = Hash.new(0.0)
    tagwords = Hash.new{|hash, key| hash[key] = Array.new}
    tagendings = Hash.new{|hash, key| hash[key] = Array.new}
    wordtags = Hash.new{|hash, key| hash[key] = Hash.new(0.0)}
    endingtags = Hash.new{|hash, key| hash[key] = Hash.new(0.0)}
    wordentropies = Hash.new(0.0)
    endingentropies = Hash.new(0.0)

    #open the input file
    f = File.open("RegrInput\\#{filename}","r:utf-8")
    
    f.each_line.with_index do |line, lineindex|
        if line.strip != "" and lineindex > 0
            line1 = line.split("\t")
            token = line1[0]
            goldtag = line1[1]
            othertags = line1[2..-2]
            othertags.each.with_index do |autotag,taggerindex|
                if autotag == goldtag
                    tagcorrect[goldtag][taggerlist[taggerindex]] += 1
                end
            end
            tagtotal[goldtag] += 1
            tagwords[goldtag] << token
            
            if goldtag == "" #sanity check, should not happen
                STDERR.puts line
            end
            wordtags[token][goldtag] += 1
            if token.length > 1
               ending = token[-2..-1]
            else
               ending = token[-1]
            end
            tagendings[goldtag] << ending
            endingtags[ending][goldtag] += 1
        end
    end
    wordtags.each_pair do |token, taghash|
        wordentropies[token] = entropy(taghash)
    end
    endingtags.each_pair do |ending, taghash|
        endingentropies[ending] = entropy(taghash)
    end

    
    tagtotal.each_pair do |tag,total|
        accs = [] #the array for storing accuracies for every tag achieved by every tagger
        taggerlist.each do |tagger|
            accs << tagcorrect[tag][tagger]/total
        end
        ttr = tagwords[tag].uniq.length.to_f/tagwords[tag].length
        
        entr_token = 0.0
        tagwords[tag].uniq.each do |word|
            wordfreq = tagwords[tag].count(word).to_f/tagwords[tag].length
            entr_token += wordentropies[word]*wordfreq
        end

        entr_ending = 0.0
        tagendings[tag].uniq.each do |ending|
            endingfreq = tagendings[tag].count(ending).to_f/tagendings[tag].length
            entr_ending += endingentropies[ending]*endingfreq
        end
        o.puts "#{tag}\t#{accs.join("\t")}\t#{total}\t#{ttr}\t#{entr_token}\t#{entr_ending}" #output the accuracy and the predictors
    end
end
