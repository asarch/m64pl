#!/usr/bin/perl

use strict;
use warnings;

use Gtk2 '-init';
use Gtk2::GladeXML;

use File::Find::Rule;
use File::Basename;

#---------------------------------------------------------------------
#  Global vars
#---------------------------------------------------------------------
my $glade = Gtk2::GladeXML->new('m64.glade');
my @files;
my $selected_game;

#---------------------------------------------------------------------
#  Initialization
#---------------------------------------------------------------------
@files = sort(File::Find::Rule->name("*.z64")->in("/home/share/roms/n64/data"));
$selected_game = $files[0];

#---------------------------------------------------------------------
#  Main process
#---------------------------------------------------------------------
sub launch {
	system("mupen64plus --fullscreen \"$selected_game\"");
}
#---------------------------------------------------------------------
#  Main window
#---------------------------------------------------------------------
my $window = $glade->get_widget('window1');
$window->signal_connect(destroy => sub {Gtk2->main_quit});
$window->set_default_size(800, 600);
$window->set_title('mupen64plus');

#---------------------------------------------------------------------
#  Exit button
#---------------------------------------------------------------------
my $quit_button = $glade->get_widget('button3');
$quit_button->signal_connect(clicked => sub {Gtk2->main_quit});

#---------------------------------------------------------------------
#  Game list
#---------------------------------------------------------------------
my $treeview = $glade->get_widget('treeview1');
my $model = Gtk2::ListStore->new('Glib::String');
my $renderer = Gtk2::CellRendererText->new;
my $column = Gtk2::TreeViewColumn->new_with_attributes("Name", $renderer, text => 0);

$treeview->set_model($model);
$treeview->append_column($column);
$model->set($model->append, 0, $_) foreach @files;
$treeview->set_cursor(Gtk2::TreePath->new_from_string('0'), $column, 1);

# Busqueda de juego
my $entry = $glade->get_widget('entry1');
$entry->signal_connect(changed => sub 
	{
		my $regexp = $entry->get_text;
		$model->clear;

		foreach (@files) {
			$model->set($model->append, 0, $_) if /$regexp/i;
		}
	}
);

$treeview->signal_connect(
	'cursor-changed' => sub {
		my $iter = $treeview->get_selection->get_selected;
		my $sel = $model->get($iter, 0);
		$selected_game = $sel;
	}
);

#---------------------------------------------------------------------
#  Button "Clear" for the entry box
#---------------------------------------------------------------------
my $clear = $glade->get_widget('button2');

$clear->signal_connect(clicked => sub {
		$entry->set_text('');
		$entry->grab_focus;
	}
);

#---------------------------------------------------------------------
#  Start game button
#---------------------------------------------------------------------
my $exec_button = $glade->get_widget('button1');

$exec_button->signal_connect(clicked => sub {launch});

#---------------------------------------------------------------------
#  Toolbar
#---------------------------------------------------------------------
my $exit = $glade->get_widget('imagemenuitem5');
$exit->signal_connect(activate => sub {Gtk2->main_quit});

my $toolbar = $glade->get_widget('toolbar1');
my $exit_item = Gtk2::ToolButton->new_from_stock('gtk-quit');
my $execute_item = Gtk2::ToolButton->new_from_stock('gtk-execute');

$exit_item->signal_connect(clicked => sub {Gtk2->main_quit});
$execute_item->signal_connect(clicked => sub {launch});

$toolbar->insert($exit_item, -1);
$toolbar->insert(Gtk2::SeparatorToolItem->new, -1);
$toolbar->insert($execute_item, -1);

$window->show_all;
Gtk2->main;
