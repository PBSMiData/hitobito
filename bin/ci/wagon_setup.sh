#  Copyright (c) 2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


# set up everything required to run rake jobs for hitobito wagons on jenkins

cd hitobito

cp Wagonfile.ci Wagonfile

bundle install --path vendor/bundle

for d in ../hitobito_*; do
  cp Gemfile.lock $d
  mkdir -p $d/.bundle
  bundle_config=$d/.bundle/config
  echo "---" > $bundle_config
  echo "BUNDLE_PATH: ../hitobito/vendor/bundle" >> $bundle_config
  echo "BUNDLE_DISABLE_SHARED_GEMS: '1'" >> $bundle_config
done

rm -rf tmp/tarantula
