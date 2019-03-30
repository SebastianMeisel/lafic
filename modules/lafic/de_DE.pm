# lafic::de_DE - some typographic corrections for german
# language, when lafic files are converted to LaTeX
 
# Copyright (C) 2019  Sebastian Meisel

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth
# Floor, Boston, MA  02110-1301, USA.  

use strict;
package lafic::de_DE;

sub LaTeX {
    # $is_par = marker, that we work on $par
    # my $is_par;
    
    # work variable
    my $line = shift;
  
    # optional argument
    # my $argument = shift;
    # if (defined $argument){
    # 	eval "\$line = \$$argument;";
    # }
    # # if no argument given work on $par
    # else {$line = $main::par; $is_par = 1}

    
    # Geschützes Leerzeichen zwischen Abkürzungen aus
    # Einzelbuchstaben wie "z. B."
    $line =~ s/(\W[[:alpha:]]\.)\s([[:alpha:]]\.)/$1\\,$2/mg;

  
    # und nach  Titeln, sowie nach Herr und Frau
    $line =~ s/(Dr\.|Prof\.|Herr|Frau)\s([[:alpha:]])/$1~$2/mg;

    # und in Datumsangaben
    $line =~ s/([0-9]{1,2}\.)\s?([0-9]{1,2}\.)\s?([0-9]{4})/$1\\,$2\\,$3/mg;

    # # write $par or given variable
    # if (defined $is_par) {$main::par = $line}
    # else {eval "\$main::$argument = \"$line\";"}

    return $line;
}

return 1;
