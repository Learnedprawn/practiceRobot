*** Settings ***
Documentation       Level 2 Robot which orders robots automatically
Library             RPA.HTTP
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.PDF
Library             OperatingSystem
Library             RPA.Archive
Task Teardown       Close Browser

*** Variables ***
${robot website}    https://robotsparebinindustries.com/#/robot-order
${csv link}         https://robotsparebinindustries.com/orders.csv
${csv table}
${receipt html}

*** Keywords ***
Open website
    Open Browser    ${robot website}    Edge
    Maximize Browser Window
    
Click dialog box
    Click Button    class:btn-dark

Download csv
    Download    ${csv link}    overwrite=${True}

Order robots
    [Arguments]    ${csv}
    Select From List By Index    id:head    ${csv}[Head]
    Select Radio Button    body    ${csv}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${csv}[Legs]
    Input Text    id:address    ${csv}[Address]
    Wait Until Keyword Succeeds    10x    0.5 sec    Click order button and check if receipt visible

Read csv into table
    ${csv table}    Read table from CSV    orders.csv    header=${True}
    Return From Keyword    ${csv table}

Click order button and check if receipt visible
    Wait And Click Button    id:order
    Wait Until Element Is Visible    id:receipt
    

Record order
    [Arguments]    ${order_num}
    ${receipt html}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt html}    ${CURDIR}${/}delete_me${/}receipt_of_robot_${order_num}.pdf    overwrite=${True}
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    css:img[alt="Head"]
    Wait Until Element Is Visible    css:img[alt="Body"]
    Wait Until Element Is Visible    css:img[alt="Legs"]
    Screenshot    id:robot-preview-image    ${CURDIR}${/}temp_photos${/}robot_of_robot_${order_num}.png
    Open Pdf    ${CURDIR}${/}delete_me${/}receipt_of_robot_${order_num}.pdf
    Add Watermark Image To Pdf    image_path=${CURDIR}${/}temp_photos${/}robot_of_robot_${order_num}.png    output_path=${CURDIR}${/}temp${/}receipt_with_image_of_robot_${order_num}.pdf
    Close Pdf

Order next
    Wait And Click Button    id:order-another

Create temp output for pdfs
    Create Directory    ${CURDIR}${/}temp

Zip pdf files
    Archive Folder With Zip    ${CURDIR}${/}temp    ${OUTPUT_DIR}${/}PDFs.zip

Delete all extra files except zip
    Empty Directory     ${CURDIR}${/}temp
    #Remove Directory    ${CURDIR}${/}temp
    Empty Directory    ${CURDIR}${/}delete_me
    #Remove Directory    ${CURDIR}${/}delete_me
    Empty Directory    ${CURDIR}${/}temp_photos    
    #Remove Directory    ${CURDIR}${/}temp_photos

*** Tasks ***
Order robots according to the csv File
    Open website
    Click dialog box
    Download csv
    ${csv table}    Read csv into table 
    Log    ${csv table}
    FOR    ${element}    IN    @{csv table}
        Order robots    ${element}
        Record order    ${element}[Order number]
        Order next
        Click dialog box
    END
    Zip pdf files
    Delete all extra files except zip
    
    
