# This file is part of Product Opener.
#
# Product Opener
# Copyright (C) 2011-2019 Association Open Food Facts
# Contact: contact@openfoodfacts.org
# Address: 21 rue des Iles, 94100 Saint-Maur des Fossés, France
#
# Product Opener is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

ProductOpener::ProducersFood - special features for food products manufacturers

=head1 DESCRIPTION

C<ProductOpener::ProducersFood> implements special features that are available
on the platform for producers, specific to food producers.

=cut

package ProductOpener::ProducersFood;

use utf8;
use Modern::Perl '2017';
use Exporter qw(import);


BEGIN
{
	use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	@EXPORT_OK = qw(

		&detect_possible_improvements

	);	# symbols to export on request
	%EXPORT_TAGS = (all => [@EXPORT_OK]);
}

use ProductOpener::Config qw(:all);
use ProductOpener::Store qw(:all);
use ProductOpener::Tags qw(:all);
use ProductOpener::Food qw(:all);

use Log::Any qw($log);


=head1 FUNCTIONS

=head2 detect_possible_improvements( PRODUCT_REF )

Run all functions to detect food product improvement opportunities.

=cut

sub detect_possible_improvements($) {

	my $product_ref = shift;

	$product_ref->{improvements_tags} = [];

	detect_possible_improvements_compare_nutrition_facts($product_ref);
	detect_possible_improvements_nutriscore($product_ref);
}

=head2 detect_possible_improvements_nutriscore( PRODUCT_REF )

Detect products that can get a better NutriScore grade with a slight variation
of nutrients like sugar, salt, saturated fat, fiber, proteins etc.

=cut

sub detect_possible_improvements_nutriscore($) {

	my $product_ref = shift;

	$log->debug("detect_possible_improvements_nutriscore - start") if $log->debug();

}

=head2 detect_possible_improvements_compare_nutrition_facts( PRODUCT_REF )

Compare the nutrition facts to other products of the same category to try
to identify possible improvement opportunities.

=cut

sub detect_possible_improvements_compare_nutrition_facts($) {

	my $product_ref = shift;

	my $categories_nutriments_ref = $categories_nutriments_per_country{"world"};

	$log->debug("detect_possible_improvements_compare_nutrition_facts - start") if $log->debug();

	return if not defined $product_ref->{nutriments};
	return if not defined $product_ref->{categories_tags};

	my $i = @{$product_ref->{categories_tags}} - 1;

	while (($i >= 0)
		and	not ((defined $categories_nutriments_ref->{$product_ref->{categories_tags}[$i]})
			and (defined $categories_nutriments_ref->{$product_ref->{categories_tags}[$i]}{nutriments}))) {
		$i--;
	}
	# categories_tags has the most specific categories at the end

	if ($i >= 0) {

		my $specific_category = $product_ref->{categories_tags}[$i];
		$product_ref->{compared_to_category} = $specific_category;

		$log->debug("detect_possible_improvements_compare_nutrition_facts" , { specific_category => $specific_category}) if $log->is_debug();

		# check major nutrients
		my @nutrients = qw(fat saturated-fat sugars salt);

		foreach my $nid (@nutrients) {

			if ((defined $product_ref->{nutriments}{$nid . "_100g"}) and ($product_ref->{nutriments}{$nid . "_100g"} ne "")
				and (defined $categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_std"})) {

				$log->debug("detect_possible_improvements_compare_nutrition_facts" ,
					{ nid => $nid, product_100g => $product_ref->{nutriments}{$nid . "_100g"},
					category_100g => $categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_100g"},
					category_std => $categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_std"}
					} ) if $log->is_debug();

				if ($product_ref->{nutriments}{$nid . "_100g"}
					> ($categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_100g"} + 1 * $categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_std"}) ) {

					push @{$product_ref->{improvements_tags}}, "en:nutrition-high-$nid-value-for-category";
				}
				if ($product_ref->{nutriments}{$nid . "_100g"}
					> ($categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_100g"} + 2 * $categories_nutriments_ref->{$specific_category}{nutriments}{$nid . "_std"}) ) {

					push @{$product_ref->{improvements_tags}}, "en:nutrition-very-high-$nid-value-for-category";
				}
			}
		}
	}
}


1;
