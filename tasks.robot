*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library            RPA.Browser.Selenium
Library            RPA.HTTP
Library            RPA.Tables
Library            RPA.PDF
Library            RPA.Windows
Library            RPA.Archive


*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order
${file}           https://robotsparebinindustries.com/orders.csv

*** Keywords ***
Open the robot order website
    Open Available Browser          ${url}       
    Maximize Browser Window
    
Close the annoying modal
    Click Element                   xpath:/html/body/div[1]/div/div[2]/div/div/div/div/div/button[1]

Get orders
    Download                  ${file}                            overwrite=true
    @{list_orders}            Read table from CSV                orders.csv   
    [Return]                  @{list_orders}    

Fill the from
    [Arguments]        ${orders}

    Select From List By Value        xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[1]/select        ${orders}[Head]
    Select Radio Button              body                                                                    ${orders}[Body]
    Input Text                       xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[3]/input         ${orders}[Legs]
    Input Text                       xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[4]/input         ${orders}[Address]


    Click Element                    xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/button[1]    
    Wait Until Keyword Succeeds      10    0.5s           Send form 
Send form    
    Click Element                    xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/button[2]

Store the receipt as a PDF file
    [Arguments]        ${orders}
    Wait Until Element Is Visible                                   xpath:/html/body/div[1]/div/div[1]/div/div[1]/div/div
    ${receipt}                            Get Element Attribute     xpath:/html/body/div[1]/div/div[1]/div/div[1]/div/div        outerHTML
    ${pdf}                                Html To Pdf               ${receipt}                                                   receipts/${orders}.pdf
    [Return]                              receipts/${orders}.pdf

Take a screenshot of the robot
    [Arguments]          ${orders}
    ${screenshot}        Capture Element Screenshot       xpath://*[@id="robot-preview-image"]                screenshot/${orders}.png
    [Return]             ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]          ${screenshot}        ${pdf}    ${order}
    Open Pdf    ${pdf}
    Add Watermark Image To PDF
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=receipts/${order}[Order number].pdf
    Close Pdf
    
Download and Store the receipt
        [Arguments]          ${order}
        Sleep                                5 
        ${screenshot}     Take a screenshot of the robot       ${order}[Order number]
        ${pdf}            Store the receipt as a PDF file      ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file     ${screenshot}                    ${pdf}            ${order}

Order another Robot 
    Wait Until Element Is Visible    xpath:/html/body/div[1]/div/div[1]/div/div[1]/div/button
    Click Element                    xpath:/html/body/div[1]/div/div[1]/div/div[1]/div/button


Archive output PDFs
    ${zip_file_name}    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip
    ...    ${CURDIR}/receipts
    ...    ${zip_file_name}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    @{list_orders}            Get orders
    FOR    ${order}    IN    @{list_orders}
        Close the annoying modal
        Fill the from                        ${order}
        Download and Store the receipt       ${order}
        Order another Robot
    END        
    Archive output PDFs


