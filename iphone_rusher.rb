require "selenium-webdriver"
require "date"

class IphoneRusher
  attr_reader :driver, :wait
  def initialize
    # configure the driver
    options = Selenium::WebDriver::Chrome::Options.new
    # options.add_argument('--headless')
    @driver = Selenium::WebDriver.for :chrome, options: options
    @wait = Selenium::WebDriver::Wait.new(:timeout => 20)
  end

  def rush
    login
    add_to_cart
    purchase
    refresh_until
  end

  def login
    # 上苹果官网
    driver.navigate.to "https://apple.com.cn"

    # 点购物袋 
    driver.find_element(xpath: '//*[@id="ac-gn-bag"]/div/a').click
    wait.until { driver.find_element(xpath: '//*[@id="ac-gn-bagview-content"]/nav/ul/li[5]/a') }
    if element_exist?(xpath: '//*[@id="ac-gn-bagview-content"]/nav/ul/li[5]/a')
      # 点登录
      driver.find_element(xpath: '//*[@id="ac-gn-bagview-content"]/nav/ul/li[5]/a').click
      input_account_and_click_login_button
    end
    if login_failed?
      if element_exist?(xpath: '//*[@id="bag-content"]/div/div[2]/div/div[1]/a')
        driver.find_element(xpath: '//*[@id="bag-content"]/div/div[2]/div/div[1]/a').click
      end
      input_account_and_click_login_button
    end
  end
  
  def add_to_cart
    wait.until { driver.find_element(xpath: '//*[@id="ac-gn-bag"]') }
    driver.find_element(xpath: '//*[@id="ac-gn-bag"]').click
    wait.until { driver.find_element(css: '#ac-gn-bag') }
    driver.find_element(css: '#ac-gn-bag').click
  end

  def input_account_and_click_login_button
    wait.until { driver.find_element(xpath: '//*[@id="signIn.customerLogin.appleId"]') }
    # 如果没有用户名
    if driver.find_element(xpath: '//*[@id="signIn.customerLogin.appleId"]').attribute('value').empty?
      # 输入用户名
      driver.find_element(xpath: '//*[@id="signIn.customerLogin.appleId"]').send_keys '<your_apple_id>'
    end
    # 输入密码
    driver.find_element(xpath: '//*[@id="signIn.customerLogin.password"]').send_keys '<your_password>'
    # 点击登录
    driver.find_element(xpath: '//*[@id="signin-submit-button"]').click
    sleep 5
  end

  def jump_to_signin_path?
    driver.current_url.include?('shop/signIn')
  end

  def login_failed?
    driver.current_url.include?('shop/bag')
  end

  def refresh_page
    driver.navigate.refresh
  end

  def purchase
    wait.until { driver.find_element(css: '#ac-gn-bag') }
    driver.find_element(css: '#ac-gn-bag').click
    wait.until { driver.find_element(xpath: '//*[@id="ac-gn-bagview-content"]/a') }
    driver.find_element(xpath: '//*[@id="ac-gn-bagview-content"]/a').click
    driver.navigate.to 'https://secure4.www.apple.com.cn/shop/checkout/start'
    if element_exist?(xpath: '//*[@id="shoppingCart.actions.checkout"]')
      driver.find_element(xpath: '//*[@id="shoppingCart.actions.checkout"]').click
    else
      wait.until { driver.find_element(xpath: '//*[@id="signIn.customerLogin.password"]') }
      driver.find_element(xpath: '//*[@id="signIn.customerLogin.password"]').send_keys '<your_password>'
      driver.find_element(xpath: '//*[@id="signin-submit-button"]').click
      sleep 5
    end
    
    wait.until { driver.find_element(css: '#fulfillmentOptionButtonGroup1') }
    sleep 5
    driver.find_element(xpath: '//*[@id="checkout-container"]/div/div[6]/div[1]/div[2]/div/div/div[1]/div/div/div/fieldset/div[1]/div[2]').click
  end

  def refresh_until
    while !any_store_selectable?
      refresh_page
    end
    select_store
  end
  

  def any_store_selectable?
    !element_exist?(css: '.is-error')
  end

  def element_exist?(xpath: nil, css: nil)
    begin
      if xpath
        driver.find_element(xpath: xpath)
      elsif css
        driver.find_element(css: css)
      end
    rescue Selenium::WebDriver::Error::NoSuchElementError
      return false
    end
  end

  def select_store
    driver.find_elements(css: '.as-storelocator-searchresultlist .as-storelocator-searchitem').first.click
    drop = driver.find_element(id: "#{Date.today.to_s}timeWindows")
    choose = Selenium::WebDriver::Support::Select.new(drop)
    choose.select_by(:index, 2)
    driver.find_element(id: 'rs-checkout-continue-button-bottom').click
    wait.until { driver.page_source.include?('你的身份证或护照号') }
    driver.find_element(name: 'nationalId').send_keys '<your_id_num>'

    driver.find_element(id: 'rs-checkout-continue-button-bottom').click
    wait.until { driver.find_element(id: 'checkout.billing.billingOptions.options.2') }
    driver.find_element(id: 'checkout.billing.billingOptions.options.2').click
    driver.find_element(id: 'rs-checkout-continue-button-bottom').click

    wait.until {driver.find_element(css: '.rs-review-header-text')}
    driver.find_element(id: 'rs-checkout-continue-button-bottom').click
  end
end


IphoneRusher.new.rush
