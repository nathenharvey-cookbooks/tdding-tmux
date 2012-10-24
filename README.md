TDDing tmux
===========
This is the final version of the TDD talk I gave at #ChefSummit.

Getting Started
---------------
0. Fork the repository
1. Clone the repository

        git clone git://github.com/sethvargo/tdding-tmux.git

2. Run the `bundle` command to get started


Adding the Testing Gems
-----------------------
Here's the updated `Gemfile`. There's more information about each gem later.

```ruby
source :rubygems

gem 'chef'
gem 'chefspec'
gem 'fauxhai'
gem 'foodcritic'
gem 'right_aws' # shut the fuck up aws cookbook
gem 'strainer'

# Guard
gem 'guard'
gem 'guard-bundler'
gem 'guard-rspec'
gem 'rb-fsevent'
gem 'terminal-notifier-guard'
```

#### Chef
...Duh!

#### ChefSpec

#### Fauxhai

#### Foodcritic

#### Strainer

#### Guard

Adding Custom Foodcritic Rules
------------------------------
Foodcritic provides great rules, but you might want to add your own or Etsy's, for example:

    git clone git@github.com:customink-webops/foodcritic-rules.git foodcritic/customink
    git clone git@github.com:etsy/foodcritic-rules.git foodcritic/etsy

Now you can run include the custom foodcritic rules like so:

    bundle exec foodcritic -I foodcritic/* COOKBOOK

I'd actually advise not using submodules though, so let's:

    rm -rf foodcritic/*/.git


Create the tmux Cookbook
------------------------
(Yes, there's a community site version, but we are TDDing!)

    knife cookbook create tmux

For this example, we are writing a very simple use case, mostly for demonstration purposes. Let's remove all the things we won't need to make things cleaner:

    rm -rf cookbooks/tmux/definitions && \
    rm -rf cookbooks/tmux/files && \
    rm -rf cookbooks/tmux/libraries && \
    rm -rf cookbooks/tmux/providers && \
    rm -rf cookbooks/tmux/resources

Just to keep sanity, let's edit the `metadata.rb file`:

```ruby
# cookbooks/tmux/metadata.rb
maintainer 'Da Community'
maintainer_email 'community@opscode.com'
license 'I own this shit'
description 'Installs/Configures tmux'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.0.1'
```

Writing the First Spec
----------------------
1. Create the `spec` directory and `spec_helper.rb`:

        mkdir spec && touch spec/spec_helper.rb

2. Open up `spec/spec_helper.rb` and add the following:

    ```ruby
    require 'chefspec'
    require 'fauxhai'
    ```

    This is obviously very simple, but as your specs get more complex, you'll want to add helper methods, additional modules, etc. It's best to have a spec_helper from the get-go.

3. Create the `cookbooks/tmux/spec` directory and the `default_spec.rb`:

        mkdir -p cookbooks/tmux/spec && touch cookbooks/tmux/spec/default_spec.rb

4. Include our `spec_helper` at the top of the spec:

    ```ruby
    # cookbooks/tmux/spec/default_spec.rb
    require 'spec_helper'
    ```

5. Write our first test:

    ```ruby
    # cookbooks/tmux/spec/default_spec.rb
    require 'spec_helper'

    describe 'tmux::default' do
      let(:runner) { ChefSpec::ChefRunner.new.converge('tmux::default') }

      it 'should install the tmux package' do
        runner.should install_package 'tmux'
      end

      it 'should create the tmux.conf file' do
        runner.should create_file('/etc/tmux.conf')
      end
    end
    ```

    This makes perfect sense, right? Super simple. Very concise. This is why I love ChefSpef. In fact, some people would argue that it's a useless test - Chef will test that it's action completes successfully. But think about regression and it makes way more sense. What if you accidentally delete that line of code? Will Chef tell you that your run failed? No, but these specs would.

6. Be OCD and add color to testing output:

        echo '--color' >> .rspec

7. Run the tests!

        bundle exec rspec cookbooks/tmux/spec/default_spec.rb

    And we broke the Internet:

    ```text
    Failures:

      1) tmux::default should install the tmux package
         Failure/Error: let(:runner) { ChefSpec::ChefRunner.new.converge('tmux::default') }
         TypeError:
           can't convert Symbol into Integer
         # ./cookbooks/bluepill/attributes/default.rb:18:in `[]'
         # ./cookbooks/bluepill/attributes/default.rb:18:in `from_file'
         # ./cookbooks/tmux/spec/default_spec.rb:4:in `block (2 levels) in <top (required)>'
         # ./cookbooks/tmux/spec/default_spec.rb:7:in `block (2 levels) in <top (required)>'

      2) tmux::default should create the tmux.conf file
         Failure/Error: let(:runner) { ChefSpec::ChefRunner.new.converge('tmux::default') }
         TypeError:
           can't convert Symbol into Integer
         # ./cookbooks/bluepill/attributes/default.rb:18:in `[]'
         # ./cookbooks/bluepill/attributes/default.rb:18:in `from_file'
         # ./cookbooks/tmux/spec/default_spec.rb:4:in `block (2 levels) in <top (required)>'
         # ./cookbooks/tmux/spec/default_spec.rb:11:in `block (2 levels) in <top (required)>'

    Finished in 0.12179 seconds
    2 examples, 2 failures

    Failed examples:

    rspec ./cookbooks/tmux/spec/default_spec.rb:6 # tmux::default should install the tmux package
    rspec ./cookbooks/tmux/spec/default_spec.rb:10 # tmux::default should create the tmux.conf file
    ```

    Wait, what the fuck? Why the fuck am I getting errors about fucking bluepill attributes? I'm not touching bluepill! Are you fucking serious!?

    Yea... I'm not going to explain it here, but if you take a look at the anatomy of a Chef run, this makes sense.

    After banging my head against a wall for a day or two over the summer, I realized the ChefSpec doesn't mock out all the node data. In fact, it only mocks a small subset of data... basically just enough to still be a "node". But none of the "awesomeness that is ohai" exists in memory.

    So I sought out on this quest to create open-source, freely available ohai data. The project is called [fauxhai](https://github.com/customink/fauxhai) and you all should contribute your boxes. It can only help our community grow.

    There are two options at this point - we could isolate the cookbooks in a subdirectory and have Chef within Chef to avoid any convergence problems, or we could mock an entire node. The latter sounds hard, but it's actually really easy with fauxhai.

    *Before* the `:runner`, let's setup Fauxhai:

    ```ruby
    # cookbooks/tmux/spec/default_spec.rb
    ...

    describe 'tmux::default' do
      before { Fauxhai.mock(platform: 'ubuntu', version: '12.04') }
      let(:runner) { ChefSpec::ChefRunner.new.converge('tmux::default') }

      ...
    end
    ```

    Run the specs again and:

    ```text
    Failures:

      1) tmux::default should install the tmux package
         Failure/Error: runner.should install_package 'tmux'
           No package resource named 'tmux' with action :install found.
         # ./cookbooks/tmux/spec/default_spec.rb:8:in `block (2 levels) in <top (required)>'

      2) tmux::default should create the tmux.conf file
         Failure/Error: runner.should create_file('/etc/tmux.conf')
           No file resource named '/etc/tmux.conf' with action :create found.
         # ./cookbooks/tmux/spec/default_spec.rb:12:in `block (2 levels) in <top (required)>'

    Finished in 0.14994 seconds
    2 examples, 2 failures

    Failed examples:

    rspec ./cookbooks/tmux/spec/default_spec.rb:7 # tmux::default should install the tmux package
    rspec ./cookbooks/tmux/spec/default_spec.rb:11 # tmux::default should create the tmux.conf file
    ```

    Fuck! They failed again. No, wait. We wanted them to fail. Those are real failures, since we haven't written any tests yet!

8. Those weren't actually the tests though... Those were just specs. We should also be running `knife cookbook test` and `foodcritic` for all of our cookbooks and recipes. We'll talk about that in a bit.

9. Let's setup guard to watch our files so we can "just code" and magic will happen.

    Run `guard init`:

        bundle exec guard init

    Open up the `Guardfile` and take a look around. It's actually more geared towards a Rails app, so let's fix that:

    ```ruby
    # Guardfile
    guard 'rspec', spec_paths: ['spec', 'cookbooks/*/spec'] do
      watch(%r{^spec/.+_spec\.rb$})
      watch('spec/spec_helper.rb')  { 'spec' }

      watch(%r{^cookbooks/(.+)/recipes/(.+)\.rb$}) { |m| "cookbooks/#{m[1]}/spec/#{m[2]}_spec.rb" }
      watch(%r{^cookbooks/([A-Za-z]+)/(.+)(\..*)?$}) { |m| "cookbooks/#{m[1]}/spec/*.rb" }
    end
    ```

    Notice that we had to add a `:spec_path` option to guard with a glob. I haven't found a better way to do this yet... Thoughts?

    Now we can fire up `guard`:

        bundle exec guard

    And the environment loads and we see our test fail again, but wait... the shell is still running. That's because, as we make changes, Guard will re-run our tests.

10. Let's write this recipe. Open up the default recipe and add some really super simple code:

    ```ruby
    # cookbooks/tmux/recipes/default.rb
    package 'tmux'

    template '/etc/tmux.conf' do
      source 'tmux.conf.erb'
      mode '0644'
    end
    ```

    Has anyone caught the mistake yet... We haven't actually defined `tmux.conf.erb` as a template! Why the fuck did our tests pass!? This is wrong. ChefSpec SUCKS! No, you just don't understand the difference between a unit test and an acceptance test.
    We could force this test to fail by adding another spec like this:

    ```ruby
    # cookbooks/tmux/spec/default_spec.rb

    it 'should drop the tmux.conf template' do
      runner.should create_file_with_content '/etc/tmux.conf', 'set -g prefix C-a'
    end
    ```

    This spec will now fail, saying the resource is never created and doesn't exist. Let's drop a tmux conf file and see what happens:

    ```ruby
    # cookbooks/tmux/templates/default/tmux.conf.erb
    # Use a better prefix:
    set -g prefix C-a
    unbind C-b

    # Change the default delay:
    set -sg escape-time 1

    # Set the window and panes index
    set -g base-index 1
    setw -g pane-base-index 1

    # Send prefix to ohter apps:
    bind C-a send-prefix

    # Split windows with more logical keys
    bind | split-window -h
    bind - split-window -v

    # Remap movement keys
    bind h select-pane -L
    bind j select-pane -D
    bind k select-pane -U
    bind l select-pane -R
    ```

    Save the `default_spec.rb` and you'll see the tests pass.

11. Okay, so we haven't really been "testing"... We spent all this time adding foodcritic rules, but we aren't using it. We also aren't using `knife cookbook test`.

    While `guard-strainer` is coming soon, it's not quite finished yet, so we have to hop out of guard - it was cool while it lasted. Ctrl + c to stop and forget it ever existed (for now).

    For each cookbook, we want to run:

    - foodcritic
    - knife cookbook test
    - specs
    - test kitchen (not covered in this talk)

    That looks like this:

        bundle exec foodcritic cookbooks/tmux -I foodcritic/* -f any; bundle exec knife cookbook test tmux; bundle exec rspec cookbooks/tmux/spec/*.rb

    Damn @nathenharvery! Looks like we are missing a Changelog in markdown format. Let's fix that now:

        echo 'Make @nathenharvey happy' > cookbooks/tmux/CHANGELOG.md

    Hit the up arrow and run the same command again... If we didn't use TDD before, this would become really cumbersome! That's why I wrote `strainer`.

12. Introduce Strainer.

    Strainer provides a foreman-like `Colanderfile` to define a series of tests at either the repo-level, cookbook-level, or a merge of both!

    Let's make a `Colanderfile` for tmux:

    ```text
    # cookbooks/tmux/Colanderfile
    knife: bundle exec knife cookbook test $COOKBOOK
    foodcritic: bundle exec foodcritic -I foodcritic/* -f any $SANDBOX/$COOKBOOK
    chefspec: bundle exec rspec $SANDBOX/$COOKBOOK
    ```

    Also, add '.colander' to your `.gitignore`.

    Strainer exposes the `$COOKBOOK` and `$SANDBOX` environment variables. Oh yea, I forgot about the best part of strainer - it sandboxes all your tests, and only includes the cookbooks you tell it to test (and associated dependencies). Which reminds me, hey @opscode peeps - can haz recipe-level dependencies plz!?

    Now we can use a single command `strain` for running these tests:

        bundle exec strain tmux

13. Put it on Jenkins!

    - You have this massive repository of proprietary, community, and other cookbooks.
    - You want individual builds for each cookbook (or cookbook group).
    - You can't afford 6x10^23 private github repositories.

    Introduce `script/jenkins`:

    ```bash
    #!/bin/bash
    set -e
    set +x

    git submodule update --init 2>&1 > /dev/null
    bundle install --quiet
    rm -Rf .colander
    bundle exec strain `echo $JOB_NAME | sed 's/_cookbook//'` -p ./cookbooks
    ```

    Now, just name your builds "thing"_cookbook and Jenkins will magically work!

