defmodule Iyzico.IyzipayTest do
  use Iyzico.EndpointCase
  doctest Iyzico.Iyzipay

  import Iyzico.Client

  alias Iyzico.Address
  alias Iyzico.BasketItem
  alias Iyzico.Buyer
  alias Iyzico.Card
  alias Iyzico.RegisteredCard
  alias Iyzico.PaymentRequest
  alias Iyzico.SecurePaymentRequest
  alias Iyzico.SecurePaymentHandle

  @current_locale Application.get_env(:iyzico, Iyzico)[:locale]

  setup do
    card =
      %Card{
        holder_name: "John Doe",
        number: "4059030000000009",
        exp_month: 12,
        exp_year: 2030,
        cvc: 123
      }

    buyer =
      %Buyer{
        id: "BY789",
        name: "John",
        surname: "Doe",
        phone_number: "+905350000000",
        identity_number: "74300864791",
        email: "email@email.com",
        last_login_date: "2015-10-05 12:43:35",
        registration_date: "2013-04-21 15:12:09",
        registration_address: "Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1",
        city: "Istanbul",
        country: "Turkey",
        zip_code: "34732",
        ip: "85.34.78.112"
      }

    shipping_address =
      %Address{
        address: "Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1",
        zip_code: "34742",
        contact_name: "Jane Doe",
        city: "Istanbul",
        country: "Turkey"
      }

    billing_address =
      %Address{
        address: "Nidakule Göztepe, Merdivenköy Mah. Bora Sok. No:1",
        zip_code: "34742",
        contact_name: "Jane Doe",
        city: "Istanbul",
        country: "Turkey"
      }

    binocular_item =
      %BasketItem{
        id: "BI101",
        name: "Binocular",
        category: "Collectibles",
        subcategory: "Accessories",
        type: :physical,
        price: "0.3"
      }

    game_item =
      %BasketItem{
        id: "BI103",
        name: "USB",
        category: "Electronics",
        subcategory: "USB / Cable",
        type: :physical,
        price: "0.2"
      }

    {:ok, %{card: card,
            buyer: buyer,
            shipping_address: shipping_address,
            billing_address: billing_address,
            binocular_item: binocular_item,
            game_item: game_item}}
  end

  test "completes endpoint test" do
    result = test_remote_host()

    assert is_tuple(result)
    assert elem(result, 0) == :ok
    assert is_integer(elem(result, 1))
  end

  test "completes a checkout with registered card", %{buyer: buyer,
                                                      shipping_address: shipping_address,
                                                      billing_address: billing_address,
                                                      binocular_item: binocular_item,
                                                      game_item: game_item} do
    card =
      %Card{
        holder_name: "Buğra Ekuklu",
        number: "5528790000000008",
        exp_year: 19,
        exp_month: 08,
        cvc: 543,
        registration_alias: "Buğra's credit card"
      }

    {:ok, card, metadata} =
      Iyzico.CardRegistration.create_card(card, "external_id", "conversation_id", "test@mail.com")

    assert metadata.succeed?

    card = %RegisteredCard{
      user_key: card.user_key,
      token: card.token
    }

    payment_request =
      %PaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ]
      }

    {:ok, payment, metadata} = Iyzico.Iyzipay.process_payment_req(payment_request)

    assert metadata.succeed?
    assert payment
  end

  test "completes a checkout", %{card: card,
                                 buyer: buyer,
                                 shipping_address: shipping_address,
                                 billing_address: billing_address,
                                 binocular_item: binocular_item,
                                 game_item: game_item} do
    payment_request =
      %PaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ]
      }

    {:ok, payment, metadata} = Iyzico.Iyzipay.process_payment_req(payment_request)

    assert metadata.succeed?
    assert payment
  end

  test "completes a checkout with custom api key and api secret", %{card: card,
                                                                    buyer: buyer,
                                                                    shipping_address: shipping_address,
                                                                    billing_address: billing_address,
                                                                    binocular_item: binocular_item,
                                                                    game_item: game_item} do
    payment_request =
      %PaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ]
      }

    {:ok, payment, metadata} =
      Iyzico.Iyzipay.process_payment_req(payment_request,
                                         api_key: "sandbox-yT2zmLntndFRtVaCJHrXv2IWmcEo9Kbk",
                                         api_secret: "sandbox-9YE1oC4cGz5h2YcUT8mgaDMNJQpds6mf")

    assert metadata.succeed?
    assert payment
  end

  test "completes a checkout with 3d secure enabled", %{card: card,
                                                        buyer: buyer,
                                                        shipping_address: shipping_address,
                                                        billing_address: billing_address,
                                                        binocular_item: binocular_item,
                                                        game_item: game_item} do
    payment_request =
      %SecurePaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ],
        callback_url: "http://reality-kings.com"
      }

    {:ok, artifact, metadata} =
      Iyzico.Iyzipay.init_secure_payment_req(payment_request,
                                             api_key: "sandbox-yT2zmLntndFRtVaCJHrXv2IWmcEo9Kbk",
                                             api_secret: "sandbox-9YE1oC4cGz5h2YcUT8mgaDMNJQpds6mf")

    assert metadata.succeed?
    assert artifact
  end

  test "does not finalize an unavailable payment request" do
    handle =
      %SecurePaymentHandle{
        conversation_id: "123456789",
        payment_id: "10533265",
        conversation_data: ""
      }

    assert Iyzico.Iyzipay.finalize_secure_payment_req(handle,
                                                      api_key: "sandbox-yT2zmLntndFRtVaCJHrXv2IWmcEo9Kbk",
                                                      api_secret: "sandbox-9YE1oC4cGz5h2YcUT8mgaDMNJQpds6mf") == {:error, :unavail}
  end

  test "cancels a valid payment", %{card: card,
                                    buyer: buyer,
                                    shipping_address: shipping_address,
                                    billing_address: billing_address,
                                    binocular_item: binocular_item,
                                    game_item: game_item} do
    payment_request =
      %PaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ]
      }

    {:ok, payment, _metadata} =
      Iyzico.Iyzipay.process_payment_req(payment_request)

    assert Iyzico.Iyzipay.revoke_payment!(payment.id, "123456789")
  end

  test "refunds a valid payment", %{card: card,
                                    buyer: buyer,
                                    shipping_address: shipping_address,
                                    billing_address: billing_address,
                                    binocular_item: binocular_item,
                                    game_item: game_item} do
    payment_request =
      %PaymentRequest{
        locale: @current_locale,
        conversation_id: "123456789",
        price: "0.5",
        paid_price: "0.7",
        currency: :try,
        basket_id: "B67832",
        payment_channel: :web,
        payment_group: :product,
        payment_card: card,
        installment: 1,
        buyer: buyer,
        shipping_address: shipping_address,
        billing_address: billing_address,
        basket_items: [
          binocular_item,
          game_item
        ]
      }

    {:ok, payment, _metadata} =
      Iyzico.Iyzipay.process_payment_req(payment_request)

    transaction = Enum.at(payment.transactions, 0)

    assert Iyzico.Iyzipay.refund_payment!(transaction.id, "123456789", "0.3", :try)
  end
end
