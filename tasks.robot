*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault
Library           RPA.FileSystem

*** Variables ***
#${url}           https://robotsparebinindustries.com/#/robot-order
#${file_url}      https://robotsparebinindustries.com/orders.csv
${head}           id:head
${body}           body
${legs}           xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input
${address}        id:address
${preview}        id:preview
${submit}         id:order
${order-another}    id:order-another
${robot-preview-image}    id:robot-preview-image
${modal}          css:button.btn.btn-warning
${receipt}        id:receipt
${receipt_folder}    ${CURDIR}${/}output${/}receipts
${image_folder}    ${CURDIR}${/}output${/}images
${receiptZip}     ${CURDIR}${/}output${/}receipts.zip

*** Keywords ***
Get Secret file
    ${orderurl}=    Get Secret    secret_name=orderurl
    [Return]    ${orderurl}[link]

Open the robot order website
    ${url}=    Get Secret file
    Open Available Browser    url=${url}
    Maximize Browser Window

Close the annoying modal
    Wait And Click Button    locator=${modal}

Get orders
    ${file_url}=    Collect url from user
    Download    url=${file_url}    target_file=${CURDIR}${/}orders.csv    overwrite=True
    ${csv}=    Read table from CSV    path=orders.csv
    [Return]    ${csv}

Collect url from user
    Add heading    heading=Please provide the Order Csv Url
    Add text input    name=csvUrl    label=Order CSV Url    placeholder=Order URL
    ${result}=    Run dialog
    [Return]    ${result.csvUrl}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    ${head}    ${order}[Head]
    Select Radio Button    ${body}    ${order}[Body]
    Input Text    ${legs}    ${order}[Legs]
    Input Text    ${address}    ${order}[Address]

Preview the robot
    Click Button    locator=${preview}
    Wait Until Element Is Visible    locator=${robot-preview-image}

Submit the order
    Wait Until Keyword Succeeds    10x    0.3 sec    Submit

Submit
    Click Button    locator=${submit}
    Page Should Contain Element    locator=${receipt}

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    ${receipt}
    ${receipt}=    Get Element Attribute    ${receipt}    outerHTML
    Html To Pdf    ${receipt}    ${receipt_folder}${/}${orderNumber}.pdf
    Set Local Variable    ${pdfReceipt}    ${receipt_folder}${/}${orderNumber}.pdf
    [Return]    ${pdfReceipt}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    ${robot}=    Capture Element Screenshot    ${robot-preview-image}    ${image_folder}${/}${orderNumber}.jpeg
    [Return]    ${robot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${receiptPdf}
    Open Pdf    ${receiptPdf}
    ${files}=    Create List    ${receiptPdf}    ${screenshot}
    Add Files To PDF    ${files}    ${receiptPdf}
    Close Pdf    ${receiptPdf}

Go to order another robot
    Click Button    ${order-another}

Create a ZIP file of the receipts
    Archive Folder With Zip    ${receipt_folder}    ${CURDIR}${/}output${/}receipts.zip

Check If Directory Exists
    [Arguments]    ${dir}
    ${flag}=    Does Directory Exist    path=${dir}
    [Return]    ${flag}

Clean Up
    Run Keyword If File Exists    ${receiptZip}    keyword=Delete Zip While Clean Up
    ${receiptsExists}=    Check If Directory Exists    ${receipt_folder}
    ${imagesExists}=    Check If Directory Exists    ${image_folder}
    Remove Or Create Directory    ${receiptsExists}    ${receipt_folder}
    Remove Or Create Directory    ${imagesExists}    ${image_folder}

Delete Zip While Clean Up
    Remove File    path=${receiptZip}

Remove Or Create Directory
    [Arguments]    ${folderFlag}    ${folderPath}
    IF    ${folderFlag}
        OperatingSystem.Remove Directory    ${folderPath}    recursive=True
    ELSE
        Create Directory    ${folderPath}
    END

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Clean Up
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser
