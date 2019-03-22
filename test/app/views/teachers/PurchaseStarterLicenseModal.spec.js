const factories = require('test/app/factories');
const stripeHandler = require('core/services/stripe');

const PurchaseStarterLicenseModal = require('views/teachers/PurchaseStarterLicensesModal');
const Product = require('models/Product');

describe('PurchaseStarterLicenseModal', () => {
    it('initializes state properly', () => {
        const view = new PurchaseStarterLicenseModal();
        const state = view.state;

        expect(state.get('quantityToBuy')).toEqual(10);
    });

    it('starts stripe flow after clicking pay now', () => {
        spyOn(stripeHandler, 'open');

        const view = new PurchaseStarterLicenseModal();

        const priceInCents = 1000;
        const starterLicenseProduct = new Product({
            name: 'starter_license',
            amount: priceInCents
        });

        view.products.add(starterLicenseProduct);
        view.products.trigger('change');

        const quantity = 10;
        view.$el.find('input[name="quantity"]').val(quantity);
        view.$el.find('button.pay-now-btn').click();

        expect(stripeHandler.open).toHaveBeenCalledWith({
            amount: quantity * priceInCents,
            description: 'Starter course access for 10 students',
            bitcoin: true,
            alipay: 'auto'
        });
    });

    it('posts purchase to backend after stripe callback', () => {
        const view = new PurchaseStarterLicenseModal();

        const stripeResponse = {
            token: {
                id: 'test'
            }
        };

        view.state.set('quantityToBuy', 10);
        view.onStripeReceivedToken(stripeResponse);

        const serverCall = jasmine.Ajax.requests.mostRecent();
        expect(serverCall.url).toEqual('/db/starter-license-prepaid');

        const body = serverCall.data();

        console.log(body);

        expect(parseInt(body.maxRedeemers[0])).toEqual(view.state.get('quantityToBuy'));
        expect(body.type[0]).toEqual('starter_license');
        expect(body['stripe[token]'][0]).toEqual(stripeResponse.token.id);
    });

    it('enforces maximum quantities at inputs', () => {
        const view = new PurchaseStarterLicenseModal();

        const existingPrepaids = factories.makePrepaid({
            type: 'starter_license',
            maxRedeemers: 10
        });

        view.prepaids.add(existingPrepaids);
        view.prepaids.trigger('change');

        const tooManyPrepaids = view.maxQuantityStarterLicenses - existingPrepaids.get('maxRedeemers') + 1;
        view.$el.find('input[name="quatity"]').val(tooManyPrepaids);

        const overLimitPrepaids = factories.makePrepaid({
            type: 'starter_license',
            maxRedeemers: view.maxQuantityStarterLicenses - existingPrepaids.get('maxRedeemers') + 1
        });

        view.prepaids.add(overLimitPrepaids);
        view.prepaids.trigger('change');

        expect(view.$el.find('button').attr('disabled')).toEqual('disabled');
    });

    it('enforces max purchase amount based on existing prepaids', () => {
        const view = new PurchaseStarterLicenseModal();

        const existingPrepaids = factories.makePrepaid({
            type: 'starter_license',
            maxRedeemers: 10
        });

        view.prepaids.add(existingPrepaids);
        view.prepaids.trigger('change');

        const maxPurchasesAllowed = view.maxQuantityStarterLicenses - existingPrepaids.get('maxRedeemers');
        expect(view.state.get('quantityAllowedToPurchase')).toEqual(maxPurchasesAllowed);
        expect(parseInt(view.$el.find('input[name="quantity"]').attr('max'))).toEqual(maxPurchasesAllowed);

        const overLimitPrepaids = factories.makePrepaid({
            type: 'starter_license',
            maxRedeemers: view.maxQuantityStarterLicenses - existingPrepaids.get('maxRedeemers') + 1
        });

        view.prepaids.add(overLimitPrepaids);
        view.prepaids.trigger('change');

        expect(view.state.get('quantityAllowedToPurchase')).toEqual(0);
        expect(parseInt(view.$el.find('input[name="quantity"]').attr('max'))).toEqual(0);
    });

    it('renders pricing', () => {
        const view = new PurchaseStarterLicenseModal();

        const starterLicenseProduct = new Product({
            name: 'starter_license',
            amount: 10000
        });

        view.products.add(starterLicenseProduct);
        view.products.trigger('change');

        expect(view.$el.find('.dollar-value')[0].innerHTML).toEqual('$100.00');
        expect(view.$el.find('.dollar-value')[1].innerHTML).toEqual('$1000.00');

        view.products.remove(starterLicenseProduct);
        starterLicenseProduct.set('amount', 5000);

        view.products.add(starterLicenseProduct);
        view.products.trigger('change');

        expect(view.$el.find('.dollar-value')[0].innerHTML).toEqual('$50.00');
        expect(view.$el.find('.dollar-value')[1].innerHTML).toEqual('$500.00');
    });
});
