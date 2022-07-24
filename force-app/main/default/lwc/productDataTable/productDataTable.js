import { LightningElement, api, wire, track } from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { NavigationMixin } from 'lightning/navigation';

import getRecords from '@salesforce/apex/ProductsListController.getRecords';

import getAccountRecord from '@salesforce/apex/ProductsListController.getAccountRecord';

import createQuoteLines from '@salesforce/apex/ProductsListController.createQuoteLines';

const columns = [
  { label: 'Product Name', fieldName: 'linkName', type: 'url',
      typeAttributes: {
          label: { fieldName: 'Name' },
          target: '_blank'
      },
      fixedWidth: 150
  },
  { label: 'SAP Code', fieldName: 'Product_SAP_Id__c', type: 'text', fixedWidth: 200},
  { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', fixedWidth: 150},
  { label: 'Description', fieldName: 'Description', type: 'text', fixedWidth: 500}
];

export default class ProductDataTable extends NavigationMixin(LightningElement) {
  //Quote Id, Account Price Book, Account Currency
  @api recordId;
  accountPB;
  accountCurrency;
  columns = columns;
  data = [];
  error;
  totalNumberOfRows = 1000; // stop the infinite load after this threshold count
  // offSetCount to send to apex to get the subsequent result. 0 in offSetCount signifies for the initial load of records on component load.
  offSetCount = 0;
  loadMoreStatus;
  targetDatatable; // capture the loadmore event to fetch data and stop infinite loading
  loadMore = true;
  searchMethod = "Loading";
  queryTerm = "";

  boolVisible = true;
  preselectedRows = [];
  preselectedPrdRows = [];
  selectedData = [];
  viewRowDataView = true;
  editRowDataView = false;
  prdPBEMapFinal = new Map();
  PBEListFinal = [];

  //Multi-Search options and operator
  options = [
    { label: 'None', value: 'None' },
    { label: 'Product Name', value: 'Name' },
    { label: 'Product Family', value: 'Product2.Family' },
    { label: 'Sales Order Material', value: 'Product2.Sales_Order_Material__c' },
    { label: 'Item Category', value: 'Product2.Item_Category__c' },
    { label: 'Item Division', value: 'Product2.Item_Division__c' },
    { label: 'Product Description', value: 'Product2.Description' },
    { label: 'Product Description - French', value: 'Product2.Product_Description_French__c' },
    { label: 'Extended Description', value: 'Product2.Extended_Description__c' },
    { label: 'Internal Notes', value: 'Product2.Internal_Notes__c' },
  ]
  operators = [
    { label: 'None', value: 'None' },
    { label: 'Equals', value: 'equal' },
    { label: 'Contains', value: 'contain' }
  ]
  //Multi-Search values
  //SR1
  SR1Field = "None";
  SR1Operator = "None";
  SR1Input = "";
  //SR2
  SR2Field = "None";
  SR2Operator = "None";
  SR2Input = "";
  //SR3
  SR3Field = "None";
  SR3Operator = "None";
  SR3Input = "";
  //SR4
  SR4Field = "None";
  SR4Operator = "None";
  SR4Input = "";
  //SR5
  SR5Field = "None";
  SR5Operator = "None";
  SR5Input = "";
  //Mutilpe Rows Search
  queryTermMultiSearch = {};
  isLoaded = false;

  connectedCallback() {
    //Get account currency and price level
    //Get initial chunk of data with offset set at 0
    console.log("Connected Callback...");
    this.searchMethod = "Loading";
    getAccountRecord({quoteId : this.recordId})
    .then(result => {
      result = JSON.parse(JSON.stringify(result));
      console.log("Account Price Book: " + result[0].Account.Price_Book__c);
      console.log("Account Currency: " + result[0].Account.CurrencyIsoCode);
      this.accountPB = result[0].Account.Price_Book__c;
      this.accountCurrency = result[0].Account.CurrencyIsoCode;
      this.getRecords();
    })
    .catch(error => {
      this.error = error;
      this.data = undefined;
      console.log('error : ' + JSON.stringify(this.error));
    });
  }

  getRecords() {
    console.log("getRecords...");
    this.isLoaded = true;
    getRecords({
      offSetCount : this.offSetCount,
      accountPB : this.accountPB,
      accountCurrency : this.accountCurrency,
      searchMethod : this.searchMethod,
      queryTerm : this.queryTerm,
      queryTermMultiSearch : JSON.stringify(this.queryTermMultiSearch)
    })
    .then(result => {
      // Returned result if from sobject and can't be extended so objectifying the result to make it extensible
      this.isLoaded = false;
      result = JSON.parse(JSON.stringify(result));
      if(Object.keys(result).length !== 0){
        console.log("Has results!");
        result.forEach(record => {
          record.linkName = '/' + record.Id;
          record.Description = record.Product2.Description;
        });
        this.data = [...this.data, ...result];
        this.error = undefined;
        this.loadMoreStatus = '';
        if ((this.targetDatatable && this.data.length >= this.totalNumberOfRows) || (result.length == 0)) {
          //stop Infinite Loading when threshold is reached
          this.targetDatatable.enableInfiniteLoading = false;
          //Display "No more data to load" when threshold is reached
          this.loadMoreStatus = 'No more data to load';
        }
        //Disable a spinner to signal that data has been loaded
        if (this.targetDatatable) this.targetDatatable.isLoading = false;
      } else {
        //No results, refresh the component
        console.log("No results!");
        this.isLoaded = false;
        //Show Toast
        this.showToastFinishedSearch();
        //Stop Infinite Loading when threshold is reached
        if (this.targetDatatable) {
          console.log("targetDatatable to false!");
          this.targetDatatable.isLoading = false;
          this.targetDatatable.enableInfiniteLoading = false;
        }
        //Display "No more data to load" when threshold is reached
        this.loadMoreStatus = 'No more data to load';
        //this.refreshCmp();
      }
    })
    .catch(error => {
      this.error = error;
      this.data = undefined;
      console.log('error : ' + JSON.stringify(this.error));
    });
  }

  handleLoadMore(event) {
    console.log('Load More');
    event.preventDefault();
    // increase the offset count by 20 on every loadmore event
    this.offSetCount = this.offSetCount + 20;
    //Display a spinner to signal that data is being loaded
    event.target.isLoading = true;
    //Set the onloadmore event taraget to make it visible to imperative call response to apex.
    this.targetDatatable = event.target;
    //Display "Loading" when more data is being loaded
    this.loadMoreStatus = 'Loading';
    // Get new set of records and append to this.data
    this.getRecords();
  }

  handleKeyUp(event) {
    const isEnterKey = event.keyCode === 13;
    let queryTerm = event.target.value;
    console.log("queryTerm: " + queryTerm);
    if (isEnterKey && queryTerm) {
      console.log('Hit enter key and queryTerm NOT null!');
      this.loadMoreStatus = '';
      if(this.targetDatatable != null){
        this.targetDatatable.enableInfiniteLoading = true;
      }
      this.searchMethod = "Searching";
      this.data = [];
      this.offSetCount = 0;
      this.queryTerm = queryTerm;
      this.getRecords();
    }
    if (isEnterKey && !queryTerm) {
      console.log('Hit enter key and queryTerm null!');
      this.loadMoreStatus = '';
      if(this.targetDatatable != null){
        this.targetDatatable.enableInfiniteLoading = true;
      }
      this.searchMethod = "Loading";
      this.data = [];
      this.offSetCount = 0;
      this.queryTerm = queryTerm;
      this.getRecords();
    }
  }

  handleChange(event) {

    console.log("User is changing Muti-Search!")

    const elementSR1Field = this.template.querySelector('[data-id="SR1-field"]');
    const elementSR1Operator = this.template.querySelector('[data-id="SR1-operator"]');
    const elementSR1Input = this.template.querySelector('[data-id="SR1-input"]');

    const elementSR2Field = this.template.querySelector('[data-id="SR2-field"]');
    const elementSR2Operator = this.template.querySelector('[data-id="SR2-operator"]');
    const elementSR2Input = this.template.querySelector('[data-id="SR2-input"]');

    const elementSR3Field = this.template.querySelector('[data-id="SR3-field"]');
    const elementSR3Operator = this.template.querySelector('[data-id="SR3-operator"]');
    const elementSR3Input = this.template.querySelector('[data-id="SR3-input"]');

    const elementSR4Field = this.template.querySelector('[data-id="SR4-field"]');
    const elementSR4Operator = this.template.querySelector('[data-id="SR4-operator"]');
    const elementSR4Input = this.template.querySelector('[data-id="SR4-input"]');

    const elementSR5Field = this.template.querySelector('[data-id="SR5-field"]');
    const elementSR5Operator = this.template.querySelector('[data-id="SR5-operator"]');
    const elementSR5Input = this.template.querySelector('[data-id="SR5-input"]');

    if(elementSR1Field.value && elementSR1Field.value != 'None' && elementSR1Operator.value  && elementSR1Operator.value != 'None' && elementSR1Input.value){
      let SR1Obj = {elementSRField: elementSR1Field.value, elementSROperator: elementSR1Operator.value, elementSRInput: elementSR1Input.value};
      this.queryTermMultiSearch['elementSR1'] = SR1Obj
    }

    if(!elementSR1Input.value){
      console.log("remove elementSR1")
      if ('elementSR1' in this.queryTermMultiSearch){
        delete this.queryTermMultiSearch['elementSR1'];
      }
    }

    if(elementSR2Field.value && elementSR2Field.value != 'None' && elementSR2Operator.value  && elementSR2Operator.value != 'None' && elementSR2Input.value){
      let SR2Obj = {elementSRField: elementSR2Field.value, elementSROperator: elementSR2Operator.value, elementSRInput: elementSR2Input.value};
      this.queryTermMultiSearch['elementSR2'] = SR2Obj
    }

    if(!elementSR2Input.value){
      if ('elementSR2' in this.queryTermMultiSearch){
        delete this.queryTermMultiSearch['elementSR2'];
      }
    }

    if(elementSR3Field.value && elementSR3Field.value != 'None' && elementSR3Operator.value  && elementSR3Operator.value != 'None' && elementSR3Input.value){
      let SR3Obj = {elementSRField: elementSR3Field.value, elementSROperator: elementSR3Operator.value, elementSRInput: elementSR3Input.value};
      this.queryTermMultiSearch['elementSR3'] = SR3Obj
    }

    if(!elementSR3Input.value){
      if ('elementSR3' in this.queryTermMultiSearch){
        delete this.queryTermMultiSearch['elementSR3'];
      }
    }

    if(elementSR4Field.value && elementSR4Field.value != 'None' && elementSR4Operator.value  && elementSR4Operator.value != 'None' && elementSR4Input.value){
      let SR4Obj = {elementSRField: elementSR4Field.value, elementSROperator: elementSR4Operator.value, elementSRInput: elementSR4Input.value};
      this.queryTermMultiSearch['elementSR4'] = SR4Obj
    }

    if(!elementSR4Input.value){
      if ('elementSR4' in this.queryTermMultiSearch){
        delete this.queryTermMultiSearch['elementSR4'];
      }
    }

    if(elementSR5Field.value && elementSR5Field.value != 'None' && elementSR5Operator.value  && elementSR5Operator.value != 'None' && elementSR5Input.value){
      let SR5Obj = {elementSRField: elementSR5Field.value, elementSROperator: elementSR5Operator.value, elementSRInput: elementSR5Input.value};
      this.queryTermMultiSearch['elementSR5'] = SR5Obj
    }

    if(!elementSR5Input.value){
      if ('elementSR5' in this.queryTermMultiSearch){
        delete this.queryTermMultiSearch['elementSR5'];
      }
    }
    
    console.log("queryTermMultiSearch: " + JSON.stringify(this.queryTermMultiSearch));

  }

  handleKeyUpMultiSearch(event) {
    const isEnterKey = event.keyCode === 13;
    if (isEnterKey) {
      console.log("Muti-Search Enter KeyUp!")
      if(this.queryTermMultiSearch && Object.keys(this.queryTermMultiSearch).length){
        this.loadMoreStatus = '';
        if(this.targetDatatable != null){
          this.targetDatatable.enableInfiniteLoading = true;
        }
        this.searchMethod = "Searching";
        this.data = [];
        this.offSetCount = 0;
        this.getRecords();
      };
    }
  }

  selectedRowHandler(event) {
    console.log('Row selected');
    const selectedRows = event.detail.selectedRows;
    let tempPreselectedRows = [];
    let tempPreselectedPrdRows = [];
    //console.log('selectedRows: ' + selectedRows);
    for(let i = 0; i < selectedRows.length; i++) {   
      tempPreselectedRows =[...tempPreselectedRows, selectedRows[i].Id];
      tempPreselectedPrdRows =[...tempPreselectedPrdRows, selectedRows[i].Product2Id];
    }

    this.preselectedRows = tempPreselectedRows;
    this.preselectedPrdRows = tempPreselectedPrdRows;
    this.selectedData = event.detail.selectedRows;

    let prdPBEMapFinalKeys = [...this.prdPBEMapFinal.keys()];

    if(!(prdPBEMapFinalKeys.length == 0)) {
      //console.log("prdPBEMapFinal is NOT empty!");
      let difference = prdPBEMapFinalKeys.filter(x => !this.preselectedPrdRows.includes(x));
      console.log("difference: " + difference);
      difference.forEach(PrdId => {
        if(this.prdPBEMapFinal.has(PrdId)) {
          this.prdPBEMapFinal.delete(PrdId);
        }
      })
    }

    this.selectedData.forEach(record => {

      if(!(this.prdPBEMapFinal.has(record.Product2Id))) {
        let recordInput = {
          PBEId: record.Id,
          linkName: record.linkName,
          Product2Name: record.Product2.Name,
          QuoteId: this.recordId,
          Product2Id: record.Product2Id,
          IsActive: record.IsActive,
          UnitPrice: record.UnitPrice,
          Discount: '',
          Quantity: '',
          Comment: ''
        }
        this.prdPBEMapFinal.set(record.Product2Id, recordInput);
      }

    })

    console.log("prdPBEMapFinal Keys: " + [...this.prdPBEMapFinal.keys()]);
    this.PBEListFinal = [...this.prdPBEMapFinal.values()];

  }

  showSelected(event) {
    console.log('Clicked showSelected');
    if(this.boolVisible) {
      this.boolVisible = false;
      console.log("getSelectedRows => ", this.template.querySelector('lightning-datatable').getSelectedRows());
    } else {
      this.boolVisible = true;
    }
  }

  toEditRowData(event) {
    this.PBEListFinal = [...this.prdPBEMapFinal.values()];
    this.editRowDataView = true;
    this.viewRowDataView = false;
  }

  toViewRowData(event) {
    this.PBEListFinal = [...this.prdPBEMapFinal.values()];
    this.editRowDataView = false;
    this.viewRowDataView = true;
  }

  updateValues(event) {
    console.log("event.target.data-id: " + event.target.dataset.id);
    console.log("event.target.label: " + event.target.label);
    console.log("event.target.value: " + event.target.value);
    
    let IdChanged = event.target.dataset.id
    let labelChanged = event.target.label;
    let valueChanged = event.target.value;
    let newValue = {
      [labelChanged]: valueChanged
    }
    let newValueKeys = Object.keys(newValue);

    let originalObj = this.prdPBEMapFinal.get(IdChanged);

    newValueKeys.map(x => {
      originalObj[x] =  newValue[x];
    })

    this.prdPBEMapFinal.set(IdChanged, originalObj);
    
  }

  saveQuoteLines(event) {
    console.log("saveQuoteLines");
    let quoteLinesList = [];
    this.isLoaded = true;

    this.PBEListFinal.forEach(peb => {
      if(peb.Comment == '') {
        peb.Comment = 'Empty';
      }
      if(peb.Discount == '') {
        peb.Discount = 0;
      }
      quoteLinesList.push(peb);
    })

    createQuoteLines({
      quoteLines : JSON.stringify(quoteLinesList)
    })
    .then(result => {
      this.isLoaded = false;
      this.showToast();
      // Returned result if from sobject and can't be extended so objectifying the result to make it extensible
      result = JSON.parse(JSON.stringify(result));
      setTimeout(() => {
        this.navigateToRecordPage();
      }, 2000);
    })
  }

  navigateToRecordPage() {
    console.log("navigateToRecordPage");
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.recordId,
            objectApiName: 'Quote',
            actionName: 'view'
        }
    });
  }

  refreshCmp(event) {
    console.log("refresh component")
    this.searchMethod = 'Loading';
    this.data = [];
    this.offSetCount = 0;
    const queryTermFieldSelect = this.template.querySelector('[data-id="queryTerm-field"]');
    queryTermFieldSelect.value = '';
    //SR1
    const SR1FieldSelect = this.template.querySelector('[data-id="SR1-field"]');
    SR1FieldSelect.value = 'None';
    const SR1OperatorSelect = this.template.querySelector('[data-id="SR1-operator"]');
    SR1OperatorSelect.value = 'None';
    const SR1OinputSelect = this.template.querySelector('[data-id="SR1-input"]');
    SR1OinputSelect.value = '';
    //SR2
    const SR2FieldSelect = this.template.querySelector('[data-id="SR2-field"]');
    SR2FieldSelect.value = 'None';
    const SR2OperatorSelect = this.template.querySelector('[data-id="SR2-operator"]');
    SR2OperatorSelect.value = 'None';
    const SR2OinputSelect = this.template.querySelector('[data-id="SR2-input"]');
    SR2OinputSelect.value = '';
    //SR3
    const SR3FieldSelect = this.template.querySelector('[data-id="SR3-field"]');
    SR3FieldSelect.value = 'None';
    const SR3OperatorSelect = this.template.querySelector('[data-id="SR3-operator"]');
    SR3OperatorSelect.value = 'None';
    const SR3OinputSelect = this.template.querySelector('[data-id="SR3-input"]');
    SR3OinputSelect.value = '';
    //SR4
    const SR4FieldSelect = this.template.querySelector('[data-id="SR4-field"]');
    SR4FieldSelect.value = 'None';
    const SR4OperatorSelect = this.template.querySelector('[data-id="SR4-operator"]');
    SR4OperatorSelect.value = 'None';
    const SR4OinputSelect = this.template.querySelector('[data-id="SR4-input"]');
    SR4OinputSelect.value = '';
    //SR5
    const SR5FieldSelect = this.template.querySelector('[data-id="SR5-field"]');
    SR5FieldSelect.value = 'None';
    const SR5OperatorSelect = this.template.querySelector('[data-id="SR5-operator"]');
    SR5OperatorSelect.value = 'None';
    const SR5OinputSelect = this.template.querySelector('[data-id="SR5-input"]');
    SR5OinputSelect.value = '';

    this.queryTermMultiSearch = {};

    this.getRecords();

  }

  showToast() {
    const event = new ShowToastEvent({
        title: 'Quote Line Items Created!',
        message:
            'Quote Line Items Created!',
    });
    this.dispatchEvent(event);
  }

  showToastFinishedSearch() {
    const event = new ShowToastEvent({
        title: 'Record search finished!',
        message:
            'Record search finished!',
    });
    this.dispatchEvent(event);
  }

  showToastNoRecordFound() {
    const event = new ShowToastEvent({
        title: 'Did not find any record!',
        message:
            'Did not find any record!',
    });
    this.dispatchEvent(event);
  }
  
}