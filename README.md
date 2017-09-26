<<<<<<< HEAD
<<<<<<< HEAD
* An overview of environments
* Setting up logging on different environments
* Dealing with email

## An overview of environments

So far we've been working on our project only in the context of a development environment, but it's important to consider that we're eventually going to want to deploy to a remote test environment, and hopefully soon after, a production website. A given project can have many environments, especially large projects that are entertaining multiple, concurrent development efforts. Each environment introduces new state, and managing that state can be really cumbersome if you don't have a solid set up. Therefore, it's important to start considering your environments early on in your development process.

We've already talked a bit about the centrepiece of environment management in SilverStripe, the `.env` file. Just as a reminder, this file is intended to reside above the web root to provide environment-specific variables to the project. This allows you to deploy one coherent codebase to each environment without having to write conditional logic to serve each environment. It does introduce the complexity of needing a higher level of write access to your server, however, so you'll want to make sure you have shell access or a highly privileged FTP account that will allow you to edit files above the web root.

## Setting up logging on different environments

One of the services you'll want enabled on test and, even more so, production, is good error logging and notification. In our dev environment, we want to suppress this, as we don't mind getting verbose errors, but once the project is on the web, you'll want to suppress showstopping errors as much as possible and simply log them out so you can proactively fix them.

As of version 4.0, SilverStripe uses the [PSR-3 logging](https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-3-logger-interface.md) standard. This means it is easy to swap out the logger with an alternative implementation, and allows your SilverStripe application to play nicely with other frameworks and libraries.

To log errors, just access the logger interface with Injector.

```php
use SilverStripe\Core\Injector\Injector;
use Psr\Log\LoggerInterface;

Injector::inst()->get(LoggerInterface::class)->error('Description of error');
```

Also available per the PSR-3 standard are:

* `emergency()`
* `alert()`
* `critical()`
* `warning()`
* `notice()`
* `info()`
* `debug()`
* `log()`

For a full list, see the PSR-3 documentation](http://www.php-fig.org/psr/psr-3/).

It's a good idea to throw these in your user code where appropriate. Logging can be very useful for debugging. When using the logger in your classes, you need not keep going through `Injector` to get a logger instance. A cleaner approach is to inject the logger as a dependency.

```php
namespace My\App;

use Psr\Log\LoggerInterface;
use PageController;

class MyPageController extends PageController
{
  private static $dependencies = [
    'logger' => '%$' . LoggerInterface::class
  ];
  
  protected $shouldFail = true;
  
  public $logger;
  
  public function doSomething()
  {
    if ($this->shouldFail) {
      $this->logger->log('It failed');
    }
  }
}
```

What all of these logging methods acutally do depends on the implementation of `LoggerInterface` that you're using. By default, SilverStripe ships with [Monolog](https://github.com/Seldaek/monolog), a logging library that comes with its own PSR-3 logging implementation, `Monolog\Logger`.

The `Monolog\Logger` class supports *handlers*, which must implement their own `HandlerInterface` definition. You can add as many handlers as you like. Some commonly used handlers ship with SilverStripe Framework.

Here's an example of adding an email handler. Any error that happens at or above the given logging level will send an email to an administrator. Let's make anything `error()` and above send an email.

*mysite/_config/logging.yml*
```yml
SilverStripe\Core\Injector\Injector:
  Psr\Log\LoggerInterface: 
    calls:
      EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
  EmailHandler:
      class: Monolog\Handler\NativeMailerHandler
      constructor:
        - errors@example.com
        - Error reported on example.com
        - admin@example.com
        - error
      properties:
        ContentType: text/html
        Formatter: %$SilverStripe\Logging\DetailedErrorFormatter
```

Since email is a pretty aggressive form of error notification, we probably don't want to sent it from anywhere other than the live environment. Let's put this in a conditional block.

*mysite/_config/logging.yml*
```yml
    --- 
    Name: lessons-live-logging
    Only:
      environment: live
    ---
    SilverStripe\Core\Injector\Injector:
     Psr\Log\LoggerInterface: 
      calls:
        EmailHandler: [ pushHandler, [ %$EmailHandler ] ]
    #...
```


A better option for low-level errors is writing to a log file. Let's set that up for anything over `notice()` level.

*mysite/_config/logging.yml*
```yml
    ---
    Name: lessons-all-logging
    ---
    SilverStripe\Core\Injector\Injector:
      Psr\Log\LoggerInterface: 
        calls:
          FileLogger: [ pushHandler, [ %$FileLogger ] ]
      FileLogger:
        class: Monolog\Handler\StreamHandler
        constructor:
          - "../errors.log"
          - "notice"
```

Let's make sure that error log doesn't get checked into our repository by adding it to `.gitignore`.

<<<<<<< HEAD
*.gitignore*
```
...
# ignore error log
errors.log
```

## Dealing with email
=======
So now that we have a good understanding of `ViewableData`, let's play around with some of its features. Right now, we're just returning a string to the template for our Ajax response. Let's instead return a partial template.

At the centre of dealing with Ajax responses is the use of includes in your Layout template. Let's take everything in the `.main` div, and export it to an include called `PropertySearchResults`.

*themes/one-ring/templates/SilverStripe/Lessons/Includes/PropertySearchResults.ss*
```html
<!-- BEGIN MAIN CONTENT -->
<div class="main col-sm-8">
	<% include SilverStripe/Lessons/PropertySearchResults %>				
</div>	
<!-- END MAIN CONTENT -->
=======
## What we'll cover
* What are we working towards?
* Updating the template: Working backwards
* Updating the controller to use generic data
=======
In this lesson we'll talk about filtering a list of items on a template. In a previous tutorial, we looked at filtering through form inputs. Now, we'll explore how to do that through the navigation.
>>>>>>> Begin lesson 19

## What we'll cover
* Setting up new relationships
* Adding lists of filter links
* Setting up the filtered routes
* Adding filtered link methods to DataObjects
* Filtering through controller actions
* Adding filter headers

Having a rich supply of data to work with is paramount to getting value out of this lesson, so once you get the code changes in place, it's a good idea to import the `database.sql` file that is included in the completed version of this lesson. It will provide you with a hundred or so randomly composed `ArticlePage` records that we'll be filtering.

## Setting up new relationships

Looking at our Travel Guides page, we see that there are a number of different filters we can apply in the sidebar. We have a list of categories, an archive of previous months and years, as well as tags. We won't be using tags for these articles, so let's remove that. We'll be replacing it with a filter for regions, because, optionally, each of these travel guides can pertain to a region.

Before we add the filter, let's set up that relationship. We'll add a `has_one` to `Region` on `ArticlePage` and a `has_many` from `Region` back to `ArticlePage`.

*mysite/code/ArticlePage.php*
```php
//...
	private static $has_one = [
		'Photo' => Image::class,
		'Brochure' => File::class,
		'Region' => Region::class,
	];
//...

	public function getCMSFields()
	{
		//...
		$fields->addFieldToTab('Root.Main', DropdownField::create(
			'RegionID',
			'Region',
			Region::get()->map('ID','Title')
		)->setEmptyString('-- None --'), 'Content');

		return $fields;

	}
```

*mysite/code/Region.php*
```php
//...
	private static $has_many = [
		'Articles' => ArticlePage::class,
	];
//...
```

Run a `dev/build?flush`. If you've already done the database import, there should be no changes to the database, but it's still critical to update the model.

## Adding lists of filter links

Now we can get into the meat of the lesson and start creating some filters.Let's look at our `ArticleHolderController` and make sure it can feed regions into its sidebar. Add a method called `Regions()` to `ArticleHolder` that simply dumps out all the regions on the Regions page.

*mysite/code/ArticleHolder.php*
```php
//...
class ArticleHolder extends Page {

  //...
	public function Regions ()
	{
		$page = RegionsPage::get()->first();

		if($page) {
			return $page->Regions();
		}
	}
  //...
```
In practice, you'd probably want to add a `sort()` and/or `limit()` to that list, but for demonstration purposes, a generic query will do fine.

Note that we don't just want to dump out `Region::get()`. This is a common mistake. If the Regions page were ever deleted and replaced, you'd end up with orphaned Regions that would then end up in that list.

We'll need to add these to the template. Replace the "tags" section with the list of regions.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	</div>
	<!-- END  ARCHIVES ACCORDION -->
					
	<h2 class="section-title">Regions</h2>
	<ul class="categories">
	<% loop $Regions %>
		<li><a href="$ArticlesLink">$Title <span>($Articles.count)</span></a></li>
	<% end_loop %>
	</ul>
	
	<!-- BEGIN LATEST NEWS -->
	<h2 class="section-title">Latest News</h2>
```

Getting the number of articles associated with the region is a simple call to the `Articles` relation. Every list in SilverStripe (the `SS_List` interface) exposes a `count()` method.

Notice that we're calling a non-existent method on `Region` called `$ArticlesLink`. This will return a URL to the Travel Guides section with the appropriate region filter applied. Don't worry about that just yet. We'll create it later in this lesson. It's just a placeholder for now.

While we're in this section, we should light up the list of categories in the sidebar. This is actually a bit easier than the list of regions, because `ArticleHolder` already has a `has_many` for `Categories`.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<!-- BEGIN SIDEBAR -->
	<div class="sidebar gray col-sm-4">
		
		<h2 class="section-title">Categories</h2>
		<ul class="categories">
		<% loop $Categories %>
			<li><a href="$Link">$Title <span>($Articles.count)</span></a></li>
		<% end_loop %>
		</ul>
```

Again, we invoke the aggregate method `count()` against the `ArticleCategory` object to get the number of articles it relates to. We can do this thanks to the `belongs_many_many` we defined on `ArticleCategory`.

Take a look in *ArticleCategory.php*. Remember this?
```php
	private static $belongs_many_many = [
		'Articles' => ArticlePage::class,
	];
```

It's now coming in really useful!

Like we did before, we've called a non-existent `Link()` method on the category object that we'll define later. 

Refresh the page and see that our categories are appearing correctly.

If you're wondering about the difference in semantics (`ArticlesLink()` vs `Link()`), it's just a matter of context. An `ArticleCategory` object's canonical link should be to a list of articles. It really isn't used anywhere else. A region, however, has its own detail page, so `Link()` is already claimed for that canonical state. Using a region to filter a list of articles is a special use of a region, so we should use a specially named method.

We're going to save the date archive links until the next lesson, as it introduces some complexity, but we'll lay down the basics. Let's get a few things working before we dive into that.

## Setting up the filtered routes

Let's think about what we want out of these links. We essentially have four states:

* The default state (no filters)
* Filtered by region
* Filtered by category
* Filtered by date

A good place to start is to envision what you want the routes to look like for each one of these states. We can pretty easily imagine something like this:

* `travel-guides/region/123` (show articles related to Region ID #123)
* `travel-guides/category/123` (show articles related to Category ID #123)
* `travel-guides/date/2017/05` (show articles from May 2017)

Optionally, it may be nice if we allowed the user to omit the month to show an entire year. Intuitive and semantically correct URL routes always earn big points.

The first thing we'll need in our controller is a list of allowed actions.

*mysite/code/ArticleHolderController.php*
```php
//...
class ArticleHolderController extends PageController
{

	private static $allowed_actions = [
		'category',
		'region',
		'date'
	];
```

Since we've updated a private static variable, be sure to run `?flush` at this point.

## Adding filtered link methods to DataObjects

Now that we know what our routes will look like, let's get back to the `Region` and `ArticleCategory` classes to define those link methods.

*mysite/code/Region.php*
```php
  //...
	public function ArticlesLink()
	{
		$page = ArticleHolder::get()->first();

		if($page) {
			return $page->Link('region/'.$this->ID);
		}
	}
<<<<<<< HEAD
	//...
>>>>>>> Begin lesson 18
=======
  //...
>>>>>>> Begin lesson 19
```

It's always a good idea to put a guard around the page actually existing. Never assume that the site tree will always be the same. This can cause real problems when a user has installed the project from the code repository but has not yet imported a database.

Interesting to note, the `LinkingMode()` method in our `Region` object is agnostic enough to still work on our `ArticleHolder` page:

```php
	public function LinkingMode()
	{
		return Controller::curr()->getRequest()->param('ID') == $this->ID ? 'current' : 'link';
	}
```

Let's now add the `Link()` method to the categories.

*mysite/code/ArticleCategory.php*
```php
   //...
	public function Link()
	{
		return $this->ArticleHolder()->Link(
			'category/'.$this->ID
		);
	}
  //...
```

Refresh the page and see that the categories and regions link to the correct URLs.


## Filtering through controller actions

Let's start by defining the base list of articles. We know at minimum that we want only articles that are children of this page, sorted in reverse chronological order. `ArticlePage::get()->sort('Date DESC')` may yield the same thing, but in the long term, that's not a great solution. We may someday have multiple `ArticleHolder` pages.

Ultimately what we want is for the controller to start with this base list, and each controller action will filter it down further. This is a great use case for the `init()` method, as it is executed before any actions.

*mysite/code/ArticleHolderController.php*
```php
//...
class ArticleHolderController extends PageController
{

	//...

	protected $articleList;

	protected function init ()
	{
		parent::init();

		$this->articleList = ArticlePage::get()->filter([
			'ParentID' => $this->ID
		])->sort('Date DESC');
	}
```

If you're wondering why we don't just use `Children()`, which effectively does the same thing, that's because `Children()` is a special method that modifies its list post-query. It actually returns an `ArrayList`, not a `DataList`, which would preclude us from adding filters.

We're going to want the articles paginated, so let's create a method that applies a `PaginatedList` to the `$articleList` member variable. This will be our single point of access to the list of articles that we're building.

*mysite/code/ArticleHolderController.php*
```php
//...
use SilverStripe\ORM\PaginatedList;

class ArticleHolderController extends PageController
{
  //...
	public function PaginatedArticles ($num = 10)
	{		
		return PaginatedList::create(
			$this->articleList,
			$this->getRequest()
		)->setPageLength($num);
	}
```

Back in the template, change the `<% loop %>` block to use the `$PaginatedArticles` method.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<div id="blog-listing" class="list-style clearfix">
		<div class="row">
			<% loop $PaginatedArticles %>
			<div class="item col-md-6">
			<!-- .... -->
			</div>
			<% end_loop %>
```

<<<<<<< HEAD
<<<<<<< HEAD
* Assign `$paginatedProperties` to a public property on the controller
* Explicitly pass it to the template using `customise()`.
>>>>>>> Lesson 17 complete

While we're on the topic of email, let's take some control over transactional emails in our environments. This can be a really annoying problem for a couple of reasons. For one, if we're testing with real data, we don't want transactional emails to be sent to real users from our development environment. Second, we want to be able to test whether those emails would be sent, and what their contents would be if we were in production.

A simple solution to this problem is to simply force the "to" address to go to you in the dev environment. You can configure this in the config yaml.

<<<<<<< HEAD
*mysite/_config/config.yml*
```yaml
Email:
  send_all_emails_to: 'me@example.com'
=======
=======
The next filter is for the availability date range. It actually doesn't offer a whole lot of utility to the user to display this as a toggleable filter, especially since it's actually a composite filter of `ArrivalDate` and `Nights`, so let's skip this one.
=======
For now, let's borrow the pagination HTML from the `PropertySearchResults.ss` file. If you're boiling inside about DRY violations, relax. We'll address this duplication in an upcoming lesson.
>>>>>>> Begin lesson 19

Take a deep breath, and copy and paste away. No one will know. Just make sure you change `$Results` to `$PaginatedArticles`.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<!-- BEGIN PAGINATION -->
	<% if $PaginatedArticles.MoreThanOnePage %>
	<div class="pagination">
		<% if $PaginatedArticles.NotFirstPage %>
		<ul id="previous col-xs-6">
			<li><a href="$PaginatedArticles.PrevLink"><i class="fa fa-chevron-left"></i></a></li>
		</ul>
		<% end_if %>
		<ul class="hidden-xs">
			<% loop $PaginatedArticles.PaginationSummary %>
				<% if $Link %>
					<li <% if $CurrentBool %>class="active"<% end_if %>>
						<a href="$Link">$PageNum</a>
					</li>
				<% else %>
					<li>...</li>
				<% end_if %>
			<% end_loop %>
		</ul>
		<% if $PaginatedArticles.NotLastPage %>
		<ul id="next col-xs-6">
			<li><a href="$PaginatedArticles.NextLink"><i class="fa fa-chevron-right"></i></a></li>
		</ul>
		<% end_if %>
	</div>
	<% end_if %>
	<!-- END PAGINATION -->
```

Now we're ready to add our first filter, for category. Let's define the `category()` action.

*mysite/code/ArticleHolderController.php*
```php
<<<<<<< HEAD
>>>>>>> Begin lesson 18
	public function index(HTTPRequest $request)
=======
use SilverStripe\Control\HTTPRequest;

class ArticleHolderController extends PageController
{
	
	//...
	public function category (HTTPRequest $r)
>>>>>>> Begin lesson 19
	{
		$category = ArticleCategory::get()->byID(
			$r->param('ID')
		);

<<<<<<< HEAD
<<<<<<< HEAD
		if ($bedrooms = $request->getVar('Bedrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bedrooms bedrooms",
				'RemoveLink' => HTTP::setGetVar('Bedrooms', null)
			]));

			$properties = $properties->filter([
				'Bedrooms:GreaterThanOrEqual' => $bedrooms
			]);
		}

<<<<<<< HEAD
		return [
			'Results' => $paginatedProperties
		];
	}
}
>>>>>>> Lesson 17 complete
```

<<<<<<< HEAD
Pretty straightforward, but we're forgetting something. We don't want this setting to apply to all environments. We need to ensure that this yaml is only loaded in the dev environment. We're not writing PHP, so we don't have the convenience of if/else blocks, but fortunately, the SilverStripe YAML parser affords us a basic API for conditional logic.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
```

Perhaps in the test and production environments, we want to monitor transactional email from a bit of a distance. We could force a BCC to our email address in that case.

*mysite/_config/email.yml*
```yaml
    ---
    Name: dev-email
    Only:
      environment: dev
    ---
    Email:
      send_all_emails_to: 'me@example.com'
    ---
    Name: live-email
    Except:
      environment: dev
    ---
    Email:
      bcc_all_emails_to: 'me@example.com'
=======
=======
		if ($bathrooms = $request->getVar('Bathrooms')) {
			$filters->push(ArrayData::create([
				'Label' => "$bathrooms bathrooms",
				'RemoveLink' => HTTP::setGetVar('Bathrooms', null)
			]));

			$properties = $properties->filter([
				'Bathrooms:GreaterThanOrEqual' => $bathrooms
			]);
		}

		if ($minPrice = $request->getVar('MinPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Min. \$$minPrice",
				'RemoveLink' => HTTP::setGetVar('MinPrice', null)
			]));
>>>>>>> Begin lesson 18

			$properties = $properties->filter([
				'PricePerNight:GreaterThanOrEqual' => $minPrice
			]);
		}

		if ($maxPrice = $request->getVar('MaxPrice')) {
			$filters->push(ArrayData::create([
				'Label' => "Max. \$$maxPrice",
				'RemoveLink' => HTTP::setGetVar('MaxPrice', null)
			]));

			$properties = $properties->filter([
				'PricePerNight:LessThanOrEqual' => $maxPrice
			]);
		}
=======
    $filters = [
        ['Bedrooms', 'Bedrooms', 'GreaterThanOrEqual', '%s bedrooms'],
        ['Bathrooms', 'Bathrooms', 'GreaterThanOrEqual', '%s bathrooms'],
        ['MinPrice', 'PricePerNight', 'GreaterThanOrEqual', 'Min. $%s'],
        ['MaxPrice', 'PricePerNight', 'LessThanOrEqual', 'Max. $%s'],
    ];

    foreach($filters as $filterKeys) {
        list($getVar, $field, $filter, $labelTemplate) = $filterKeys;
        if ($value = $request->getVar($getVar)) {
            $activeFilters->push(ArrayData::create([
                'Label' => sprintf($labelTemplate, $value),
                'RemoveLink' => HTTP::setGetVar($getVar, null, null, '&'),
            ]));

            $properties = $properties->filter([
                "{$field}:{$filter}" => $value
            ]);
        }
    }
>>>>>>> Lesson 18 complete
=======
		if(!$category) {
			return $this->httpError(404,'That category was not found');
		}
>>>>>>> Begin lesson 19

		$this->articleList = $this->articleList->filter([
			'Categories.ID' => $category->ID
		]);

		return [
			'SelectedCategory' => $category
		];
	}
```

We start first by checking if the category exists. If not, we throw a 404. Then, we update the article list by filtering the current one against the `many_many` relation, `Categories`. This is a wonderful example of the power of the ORM. Its abstraction layer allows us to filter by a parameter that is not necessarily a field in the database, but rather, a named relationship in our code. The filter `Categories.ID => $category->ID` simply asks for all the articles that contain the given category ID in their list of their related category IDs.

<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> Lesson 17 complete
```

This works okay, but it's kind of broad. If we have other developers on the project, they're not going to get any emails, and we also can't accurately test from our dev environment what the "to" address would actually be in production or test.

### MailCatcher

A much more thorough solution is to use a thirdparty tool to capture outgoing emails from your dev environment. There are a few of these tools available, but the one I like, and recommend, is [MailCatcher](https://mailcatcher.me/). Follow the instructions on the home page to install the software, and with just a bit of configuration, you can pipe all email into a local inbox. To browse the inbox, simply visit localhost:1080. Now, you can monitor all outgoing emails, and know exactly who would receive them and what their contents would be in a production environment.
=======
Just like our custom variable `Results`, we'll pass the `ActiveFilters` list to the template through an array.
=======
At the end of the function, we return the selected category to the template. This will be important when adding text to the page that shows the filtered state.
>>>>>>> Begin lesson 19

Notice also that we don't return a list of articles in the controller action. The articles are going to be paginated, and we want to avoid the redundancy of creating a `PaginatedList` in each controller action. We'll create a central place for that to happen in just a bit.

Test it out and see that the new filtered category state is working as expected.

Let's add our next filter for regions. It will work much the same way.

*mysite/code/ArticleHolderController.php*
```php
//...
use SilverStripe\Control\HTTPRequest;

class ArticleHolderController extends PageController
{
	//...

	public function region (HTTPRequest $r)
	{
		$region = Region::get()->byID(
			$r->param('ID')
		);

		if(!$region) {
			return $this->httpError(404,'That region was not found');
		}

		$this->articleList = $this->articleList->filter([
			'RegionID' => $region->ID
		]);

		return [
			'SelectedRegion' => $region
		];
	}
```

<<<<<<< HEAD
Reload the page, and you should have working filter buttons now!
>>>>>>> Begin lesson 18
=======
Test the regions filter in your browser and see that it's working.

## Adding filter headers

The last thing we need to do is pull our filter headers into the listings to show the user the state of the list. Each controller action returns its own custom template variables that we can check.

*themes/one-ring/templates/SilverStripe/Lessons/Layout/ArticleHolder.ss*
```html
	<div id="blog-listing" class="list-style clearfix">
		<div class="row">
			<% if $SelectedRegion %>
				<h3>Region: $SelectedRegion.Title</h3>
			<% else_if $SelectedCategory %>
				<h3>Category: $SelectedCategory.Title</h3>
			<% end_if %>

```
Give that a try and see that you now get some nice headings showing the state of the list.

One missing piece you'll notice is that the detail page still has a static sidebar. Getting this to work requires teaching a new concept, and we'll address that in the next couple of lessons.
>>>>>>> Begin lesson 19
