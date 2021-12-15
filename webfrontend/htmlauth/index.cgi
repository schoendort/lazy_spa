#!/usr/bin/perl


# Einbinden der LoxBerry-Module
use CGI;
use LoxBerry::System;
use LoxBerry::Web;
  
# Die Version des Plugins wird direkt aus der Plugin-Datenbank gelesen.
my $version = LoxBerry::System::pluginversion();
 
# Mit dieser Konstruktion lesen wir uns alle POST-Parameter in den Namespace R.
my $cgi = CGI->new;
$cgi->import_names('R');
# Ab jetzt kann beispielsweise ein POST-Parameter 'form' ausgelesen werden mit $R::form.
 
 
# Wir Übergeben die Titelzeile (mit Versionsnummer), einen Link ins Wiki und das Hilfe-Template.
# Um die Sprache der Hilfe brauchen wir uns im Code nicht weiter zu kümmern.
LoxBerry::Web::lbheader("Sample Plugin for Perl V$version", "http://www.loxwiki.eu/x/2wN7AQ", "help.html");
  
# Wir holen uns die Plugin-Config in den Hash %pcfg. Damit kannst du die Parameter mit $pcfg{'Section.Label'} direkt auslesen.
my %pcfg;
tie %pcfg, "Config::Simple", "$lbpconfigdir/pluginconfig.cfg";
 

# Wir initialisieren unser Template. Der Pfad zum Templateverzeichnis steht in der globalen Variable $lbptemplatedir.

my $template = HTML::Template->new(
    filename => "$lbptemplatedir/index.html",
    global_vars => 1,
    loop_context_vars => 1,
    die_on_bad_params => 0,
	associate => $cgi,
);
  
# Jetzt lassen wir uns die Sprachphrasen lesen. Ohne Pfadangabe wird im Ordner lang nach language_de.ini, language_en.ini usw. gesucht.
# Wir kümmern uns im Code nicht weiter darum, welche Sprache nun zu lesen wäre.
# Mit der Routine wird die Sprache direkt ins Template übernommen. Sollten wir trotzdem im Code eine brauchen, bekommen
# wir auch noch einen Hash zurück.
my %L = LoxBerry::Web::readlanguage($template, "language.ini");
  
# Checkboxen, Select-Lists sind mit HTML::Template kompliziert. Einfacher ist es, mit CGI das HTML-Element bauen zu lassen und dann
# das fertige Element ins Template einzufügen. Für die Labels und Auswahlen lesen wir aus der Config $pcfg und dem Sprachhash $L.
# Nicht mehr sicher, ob in der Config True, Yes, On, Enabled oder 1 steht? Die LoxBerry-Funktion is_enabled findet's heraus.
my $activated = $cgi->checkbox(-name => 'activated',
                                  -checked => is_enabled($pcfg{'MAIN.SOMEOTHEROPTION'}),
                                    -value => 'True',
                                    -label => $L{'BASIC.IS_ENABLED'},
                                );
# Den so erzeugten HTML-Code schreiben wir ins Template.

print "Version of this plugin is " . LoxBerry::System::pluginversion() . "<br>\n";

print "Use a variable from the config file: <i>" . %pcfg{'SECTION1.NAME'} . "</i><br>\n";

$template->param( ACTIVATED => $activated);
  
# Nun wird das Template ausgegeben.
print $template->output();
  
# Schlussendlich lassen wir noch den Footer ausgeben.
LoxBerry::Web::lbfooter();
