*** Settings ***
Documentation     Template robot main suite.
Library           Collections
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Excel.Files
Library           RPA.Tables
Library           MyLibrary
Library           RPA.HTTP
Library           RPA.Desktop
Library           RPA.PDF
Library           Collections
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.RobotLogListener
Resource          keywords.robot
Variables         MyVariables.py

*** Variables ***
${ORDERS_FILE}    ./orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    ${username}=    Get The User Name
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Display the success dialog    USER_NAME=${username}
    Log Out And Close The Browser

*** Keywords ***
Directory Cleanup
    Empty Directory    ${CURDIR}${/}pdf_files
    Empty Directory    ${CURDIR}${/}image_files

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv
    ${orders}=    Read table from CSV    ${ORDERS_FILE}
    [Return]    ${orders}

Close the annoying modal
    Click Element If Visible    xpath://button[@class="btn btn-dark"]

Fill the form
    [Arguments]    ${orders}
    Select From List By Value    name:head    ${orders}[Head]
    Click Element    id-body-${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address]

Preview the Robot
    Click Element    id:preview

Submit the order
    Click Button    //button[@id="order"]
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        Run Keyword If    '${alert}'=='True'    Click Button    //button[@id="order"]
        Exit For Loop If    '${alert}'=='False'
    END

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    content=${order_receipt_html}    output_path=${CURDIR}${/}pdf_files${/}${orderNumber}.pdf
    [Return]    ${CURDIR}${/}pdf_files${/}${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}image_files${/}${orderNumber}.png
    [Return]    ${CURDIR}${/}image_files${/}${orderNumber}.png

Go to order another robot
    Click Element    id:order-another

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log To Console    Printing Embedding image ${screenshot} in pdf file ${pdf}
    @{myfiles}=    Create List    ${screenshot}:x=0,y=0
    Open PDF    source_path=${pdf}
    Add Files To Pdf    files=${myfiles}    target_document=${pdf}    append=${True}

Create a Zip File of the Receipts
    Archive Folder With ZIP    ${CURDIR}${/}pdf_files    ${CURDIR}${/}output${/}pdf_archive.zip    recursive=True    include=*.pdf

Get The Program Author Name From Our Vault
    Log To Console    Getting Secret from our Vault
    ${secret}=    Get Secret    mysecrets
    Log    ${secret}[author] wrote this program for you    console=yes

Get The User Name
    Add heading    I am your RoboCorp Order Genie
    Add text input    myname    label=What is thy name, oh sire?    placeholder=Give me some input here
    ${result}=    Run dialog
    [Return]    ${result.myname}

Display the success dialog
    [Arguments]    ${USER_NAME}
    ${secret}=    Get Secret    mysecrets
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${USER_NAME} - all orders have been processed. Have a nice day! Developed by ${secret}[author]
    Run dialog    title=Success

Log Out And Close The Browser
    Close Browser
