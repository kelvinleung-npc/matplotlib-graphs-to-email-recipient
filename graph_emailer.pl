use JSON;
use warnings; 
use Cwd; 
use Getopt::Std; 


#############################################################################################################################################
# How to run graph_emailer.pl                                                                                                               #
#                                                                                                                                           #
#                                                                                                                                           #
# Example Table Entry with example call to graph_emailer:                                                                                   #
# [                                                                                                                                         #
# 'Table Name',                                                                                                                             #
# 'column 1',                                                                                                                               #
# 'column 2',                                                                                                                               #
# 'Grouping type if at all',                                                                                                                #
# 'Constraints',                                                                                                                            #
# 'Graph Table Number'                                                                                                                      #
# ]                                                                                                                                         #
# perl graph_emailer.pl -G 'bargraph' -I '000000000000011' -t username                                                                      #
#                                                                                                                                           #
# Meaning of flags:                                                                                                                         #
# -G defines the type of graph                                                                                                              #
# -I refers to the Graph Table entry ID                                                                                                     #
# -t the username which is then converted into their email ID to send the image to                                                          #
# -L is the label used for linegraphs to say what the line represents (only for linegraph)                                                  #
#                                                                                                                                           #
#                                                                                                                                           #
#############################################################################################################################################


my $USAGE     = "\n ALL FIELDS REQUIRED \n\n".
             "\tUsage: $0 -t <to> -f <from> -s <subject>\n".
             "\tt - comma separated list of email addresses\n".
             "\tf - source email address\n".
             "\ts - subject of email note\n".
             "\tG Graph Type to create\n\n";
getopts("t:f:s:I:G:L:") || die $USAGE;

our($opt_t,$opt_f,$opt_s,$opt_I,$opt_G,$opt_L);

my $DataDirectory = '';
chdir $DataDirectory;
my $PathToGraphGenerator = "";


sub sort_array 
{                                            #############################################
    my @unsorted_array2d = @{$_[0]};         # parameters: an unsorted 2d array          #
    my @sorted_array2d;                      # given a 2d array, sorts by x values.      #
    #if digits sort by                       # sorts by digits, unless it is a string    #
    if($unsorted_array2d[0][0] =~ /^\d+$/ ){ #############################################
        @sorted_array2d = sort{($a->[0] <=> $b->[0])} @unsorted_array2d; 
    #if alphabet sort by 
    }else{
        @sorted_array2d = sort{(lc($a->[0]) cmp lc($b->[0]))} @unsorted_array2d; 
    }
    return @sorted_array2d;
}

sub linegraph_json 
{
    my $title = $_[0];                    #########################################################################
    my $label = $_[1];                    # parameters: title of the image ex: "test.jpg"                         #
    my @x_values = @{$_[2]};              #             legend label ex: royalbritishcolumbiamuseum.com           #
    my @y_values = @{$_[3]};              #             array of x domain values ex: [11313,13123,12313]          # 
    open(FH, '>', "data".$opt_I.".json"); #             array of y range values ex: [1,2,3]                       #
    print FH '{'."\n";                    # creates a json file which is passed to generalized_graph_generator.py # 
    print FH '"image":{'."\n";            #########################################################################
    print FH '"type":"linegraph",'."\n";
    print FH "\"title\":\"$title\","."\n";
    print FH '"label_and_y_value_arrays":'.encode_json([[$label,[@y_values]]]).",\n";
    print FH '"x_value_array":'.encode_json(\@x_values)."\n";
    print FH  '}'."\n"; 
    print FH '}'."\n";
    close(FH);
    system("python $PathToGraphGenerator/generalized_graph_generator.py --json=data".$opt_I.".json")
}

sub bargraph_json 
{                                          #########################################################################
    my $title = $_[0];                     # parameters: title of the image ex: "test0000000000008.jpg"            #
    my $X = $_[1];                         #             Label of X axis                                           #
    my $Y = $_[2];                         #             Label of Y axis                                           #
    my @x_values = @{$_[3]};               #             array of x domain values ex: [11313,13123,12313]          #
    my @y_values = @{$_[4]};               #             array of y range values ex: [1,2,3]                       #
    open(FH, '>', "data".$opt_I.".json");  # creates a json file which is passed to generalized_graph_generator.py #
    print FH '{'."\n";                     #########################################################################
    print FH '"image":{'."\n";
    print FH '"type":"bargraph",'."\n";
    print FH '"title":"'.$title.'",'."\n";
    print FH '"x_label":'."\"$X\","."\n";
    print FH '"y_label":'."\"$Y\","."\n";
    print FH '"y_value_array":'.encode_json(\@y_values).",\n";
    print FH '"x_value_array":'.encode_json(\@x_values)."\n";
    print FH  '}'."\n"; 
    print FH '}'."\n";
    close(FH);
    system("python $PathToGraphGenerator/generalized_graph_generator.py --json=data".$opt_I.".json")

}

sub piechart_json 
{                                              ##########################################################################
    my $title = $_[0];                         #  parameters: title of the image ex: "test0000000000008.jpg"            #
    my $labels = $_[1];                        #              labels of piechart slices ex ["red","blue"]               #
    my $size_array = $_[2];                    #              array of numerical values ex [54,24]                      #
    open(FH, '>', "data".$opt_I.".json");      # creates a json file which is passed to generalized_graph_generator.py  #
    print FH '{'."\n";                         ##########################################################################
    print FH '"image":{'."\n";                 
    print FH '"type":"piechart",'."\n";
    print FH '"title":"'.$title.'",'."\n";
    print FH '"labels":'.encode_json($labels).",\n";
    print FH '"size_array":'.encode_json($size_array)."\n";
    print FH  '}'."\n"; 
    print FH '}'."\n";
    close(FH);
    system("python $PathToGraphGenerator/generalized_graph_generator.py --json=data".$opt_I.".json")

}

sub to_year_month_day 
{                                                                ###############################################################
    my $X_values = $_[0];                                        # converts array of epoch integer values into year month date #
    for my $index (0..scalar(@{$X_values})-1){                   ###############################################################
        my($y,$m,$d) = (localtime($X_values->[$index]))[5,4,3];
        $y += 1900;
        $m += 1;
        my $string = $y.'-'.$m.'-'.$d;
        $X_values->[$index] = $string; 
    }
}

sub separate_into_different_arrays 
{
    my @sorted_logs = @{$_[0]};      ##################################################
    my @X_values;                    # splits 2d array of pair values into            # 
    my @Y_values;                    # x value and y value arrays                     #
    for my $log (@sorted_logs){      ##################################################
        push( @X_values, $log->[0]);
        push( @Y_values, $log->[1]);
    }
    return \@X_values, \@Y_values; 
}
sub convert_array_to_int {
    #pass in a reference to an array 
    # perl style for loop 
    # $_ is the index of the loop going from 0 to (length of array - 1)
    for (0..scalar(@{$_[0]})-1){
        #implicitly convert the array via reference from string to int 
        #print $_[0]->[$_];
        $_[0]->[$_] = int($_[0]->[$_]);
    }
}

sub summate_sum 
{                                 ###############################################################
    my @X_values = @{$_[0]};      # Aggregates all matching X values in X array by summing their# 
    my @Y_values = @{$_[1]};      # Y values together.                                          #
    my %hash = ();                ###############################################################
    for (0..scalar(@X_values)-1){ 
        if(exists($hash{$X_values[$_]})){
            my $value_to_add = $Y_values[$_];
            my $summed_value = $hash{$X_values[$_]} + $value_to_add;
            $hash{$X_values[$_]} = $summed_value;
        }else{
            $hash{$X_values[$_]} = $Y_values[$_];
        }
    }

    my @array_2d; 
    for my $key (keys %hash){
        push(@array_2d, [$key,$hash{$key}])
    }

    my @sorted_array2d = sort_array(\@array_2d);
    ($X_values, $Y_values) = separate_into_different_arrays(\@sorted_array2d);
    @X_values = @{$X_values};
    @Y_values = @{$Y_values};
    convert_array_to_int(\@Y_values);
    return \@X_values, \@Y_values; 
}

sub summate_count 
{                                ###############################################################
    my @X_values = @{$_[0]};     # Groups all matching X values by count. Y value is the count #
    my @Y_values = @{$_[1]};     # of X record                                                 # 
    my %hash = ();               ###############################################################
    for (0..scalar(@X_values)-1){
        if(exists($hash{$X_values[$_]})){
            my $value = $hash{$X_values[$_]};
            $hash{$X_values[$_]} = $value + 1;
        }else{
            $hash{$X_values[$_]} = 1;
        }
    }
    my @array_2d; 
    for my $key (keys %hash){
        push(@array_2d, [$key,$hash{$key}])
    }

    my @sorted_array2d = sort_array(\@array_2d);
    ($X_values, $Y_values) = separate_into_different_arrays(\@sorted_array2d);
    return $X_values, $Y_values; 
}



sub email_hash_maker 
{                                                                       ##########################################################
    my $image_input = $_[0];                                            # parameters: Name of the image to send off              #      
    my $user = $_[1];                                                   #             username to recieve email: ex keleung      #
    my $contact = "email contact";                                      #                                                        #
    my %emailhash = (   Subject     =>    "Image Generation",           # hash formatted to send off through sendMail            #
                        To          =>    $contact,                     ##########################################################
                        From        =>    "Sender",
                        Body        =>    "<img src=\"cid:1\">",
                        Images      =>    $image_input,
                        Attachments =>    $image_input
                        );
    return %emailhash; 
}

sub sendMail 
{                                                                                               ###########################################################
   my(%parms) = @_;                                                                             # parameters: email_hash_maker($image,username)           #
   my $to             = (exists($parms{To})     ?$parms{To}     :"ReceiverEmail");              # sends email to user via ModifiedMimeMail.pl with        #
   my $from           = (exists($parms{From})   ?$parms{From}   :"Sender");                     # matplotlib graph                                        #
   my $subject        = (exists($parms{Subject})?$parms{Subject}:"Unspecified subject");        ###########################################################
   my $body           = (exists($parms{Body})   ?$parms{Body}   :"Unspecified Body");           
   my $images         = (exists($parms{Images})   ?$parms{Images}   :"No Images Given");
   my $attachments    = (exists($parms{Attachments})   ?$parms{Attachments}   :"No Attachments Given");
   my $mailfile = 'PathtoFile';
   printf STDERR "to=\"$to\"\n".
                 "from=\"$from\"\n".
                 "subject=\"$subject\"\n".
                 "body has %d characters\n",length($body) if exists($parms{Debug});
    if( open(MAIL,"| $mailfile -f $from -t $to -i $images -a $attachments -s \"$subject\"".(exists($parms{Debug}) ?"":" 2>/dev/null >/dev/null")) ) {
      printf MAIL $body;
      close(MAIL);
   }
   else {
      printf STDERR "ERROR: Failed to open MAIL, cannot send\n";
   }
}

##############################################################
# Linegraph part of the code                                 #
##############################################################
if($opt_I && lc($opt_G) eq "linegraph" && $opt_L){
    my @metadata = / Pull from Database / 

    my @data = @{$metadata[0]};   
    my $table = $data[0];         
    my $X = $data[1];             
    my $Y = $data[2];             
    my $Summation = $data[3];     
    my $Filter = $data[4];        
  
    if ($Filter eq '""'){
        @logs = / Pull from Database / 

    }else{
        @logs = / Pull from Database / 

    }

    if(scalar(@logs) == 0){
        print STDERR "Fetched data is empty. input data might be formatted incorrectly\n";
    }

    if(lc($Summation) eq 'sum'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_sum($X_values, $Y_values);
        linegraph_json("linegraph".$opt_I.".jpg",$opt_L,$X_values,$Y_values);
        sendMail(email_hash_maker("linegraph".$opt_I.".jpg",$opt_t));
    }

    elsif(lc($Summation) eq 'count'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_count($X_values,$Y_values);
        linegraph_json("linegraph".$opt_I.".jpg",$opt_L,$X_values,$Y_values);
        sendMail(email_hash_maker("linegraph".$opt_I.".jpg",$opt_t));
    
    }else{
        my @sorted_array2d = sort_array(\@logs);
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@sorted_array2d);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        convert_array_to_int($Y_values); #if there isnt a convert_array_to_int perl will keep the numbers as string still 
                                         #and when passing the value to matplotlib it make a linear line
        linegraph_json("linegraph".$opt_I.".jpg",$opt_L,$X_values,$Y_values);
        sendMail(email_hash_maker("linegraph".$opt_I.".jpg",$opt_t));
    }
}

##############################################################
# bargraph part of the code                                  #
##############################################################

elsif($opt_I && lc($opt_G) eq "bargraph"){

    my @metadata = / Pull from Database / 


    my @data = @{$metadata[0]};
    my $table = $data[0];
    my $X = $data[1];
    my $Y = $data[2];
    my $Summation = $data[3];
    my $Filter = $data[4];

    my @logs; 
    if ($Filter eq '""'){
        @logs = / Pull from Database / 
    }else{
        @logs = / Pull from Database / 
    }

    if(scalar(@logs) == 0){
        print STDERR "Fetched data is empty. input data might be formatted incorrectly\n";
    }
    if(lc($Summation) eq 'sum'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_sum($X_values, $Y_values);
        bargraph_json("bargraph".$opt_I.".jpg", $X, $Y, $X_values, $Y_values);
        sendMail(email_hash_maker("bargraph".$opt_I.".jpg",$opt_t));
    }

    elsif(lc($Summation) eq 'count'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_count($X_values,$Y_values);
        bargraph_json("bargraph".$opt_I.".jpg", $X, $Y, $X_values, $Y_values);
        sendMail(email_hash_maker("bargraph".$opt_I.".jpg",$opt_t));

    }else{
         my @sorted_array2d = sort_array(\@logs);
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@sorted_array2d);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        convert_array_to_int($Y_values);
        bargraph_json("bargraph".$opt_I.".jpg", $X, $Y, $X_values, $Y_values);
        sendMail(email_hash_maker("bargraph".$opt_I.".jpg",$opt_t));
    }
}

##############################
# Piechart part of the code  #
##############################
elsif($opt_I && lc($opt_G) eq "piechart"){

    my @metadata = / Pull from Database / 

    my @data = @{$metadata[0]};
    my $table = $data[0];
    my $X = $data[1];
    my $Y = $data[2];
    my $Summation = $data[3];
    my $Filter = $data[4];

    my @logs; 
    if ($Filter eq '""'){
        @logs = / Pull from Database / 
    }else{
        @logs = / Pull from Database / 
    }

    if(scalar(@logs) == 0){
        print STDERR "Fetched data is empty. input data might be formatted incorrectly\n";
    }

    if(lc($Summation) eq 'sum'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_sum($X_values, $Y_values);
        piechart_json("piechart".$opt_I.".jpg",$X_values,$Y_values);
        sendMail(email_hash_maker("piechart".$opt_I.".jpg",$opt_t));

    }elsif(lc($Summation) eq 'count'){
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@logs);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        ($X_values, $Y_values) = summate_count($X_values,$Y_values);
        piechart_json("piechart".$opt_I.".jpg",$X_values,$Y_values);
        sendMail(email_hash_maker("piechart".$opt_I.".jpg",$opt_t));
    
    }else{
        my @sorted_array2d = sort_array(\@logs);
        (my $X_values, my $Y_values) = separate_into_different_arrays(\@sorted_array2d);
        if(lc($X) eq 'date'){
            to_year_month_day($X_values); #convert to YMD first incase date values differ by a couple seconds 
        }
        convert_array_to_int($Y_values);
        piechart_json("piechart".$opt_I.".jpg",$X_values,$Y_values);
        sendMail(email_hash_maker("piechart".$opt_I.".jpg",$opt_t));
    }
}

else{
    print STDERR ("Didn't provide correct options");
    exit; 
}

