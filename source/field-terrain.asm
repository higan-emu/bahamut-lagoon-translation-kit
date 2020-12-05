//this file handles the terrain window.
//it is accessed by pressing B on an empty tile on the battle field.
//it displays tile coordinates, the tile type, and if in debug mode, a debug ID.

namespace field {

seek(codeCursor)

namespace terrain {
  enqueue pc
  seek($c09cb4); jsl renderCoordinates; nop #4
  seek($c09d6e); jsl renderTerrainType; rts
  seek($c09cc7); ldx #$0082        //terrain type tilemap position
  seek($c09cdc); jsl tilemapWidth  //terrain type tilemap width
  //in debug mode, the terrain window was increased in height to show the ID.
  //instead of using an entire line, this code folds the ID into the coordinates line.
  seek($c09c9e); lda #$02  //disable debug mode extra window height
  seek($c09ca5); nop #6    //disable debug mode extra window lines (for ID)
  seek($c09ccd); nop #5    //disable debug mode terrain type relocation (for ID)
  dequeue pc

  //the printed coordinates should be (2,2) less than the actual RAM values
  define xCoordinate = $90
  define yCoordinate = $91

  //A <= minimum number of tiles needed for the window
  function width {
    variable(2, coordinatesWidth)
    variable(2, terrainTypeWidth)

    php; rep #$30; phx; phy
    jsl buildCoordinatesString; render.small.width(); add #$0007; div(8); sta coordinatesWidth
    jsl buildTerrainTypeString; render.large.width(); add #$0007; div(8); sta terrainTypeWidth
    //A <= min(coordinatesWidth, terrainTypeWidth)
    cmp coordinatesWidth; bcs +; lda coordinatesWidth; +
    rep #$30; ply; plx; plp; rtl
  }

  //this is a thin wrapper around terrain.width as there wasn't space for a JSL
  //------
  //c09cdc  lda #$08  ;request eight tilemap entries
  //c09cde  sta $08   ;store the variable for writing
  //------
  function tilemapWidth {
    jsl terrain.width; sta $08; rtl
  }

  //Y => tilemap write index
  //$7e0042 => tilemap base address
  function renderCoordinates {
    variable(2, tiles)

    enter; phy
    jsl width; sta tiles
    lda tiles; jsl buildCoordinatesString; render.small.bpo4()
    lda tiles; ldx #$0030; write.bpp4()

    //write the tilemap for the coordinates string
    lda tiles; tay; plx
    sep #$20; lda #$30
    loop: {
      sta $7e0042,x; inc; inx #2
      dey; bne loop
    }
    leave; rtl
  }

  //A => terrain type
  function renderTerrainType {
    enter
    jsl buildTerrainTypeString
    ldx #$0000; txy; append.string(output, render.text)
    leave; rtl
  }

  //returns the type ID of the currently selected tile
  function getTerrainTypeID {
    variable(2, temp)

    php; rep #$30; phx
    lda {yCoordinate}; and #$00ff; asl #6; pha
    lda {xCoordinate}; and #$00ff; add $01,s
    asl; tax; pla
    lda $7f8001,x; and #$0006; lsr; cmp #$0003; bne +
    lda #$0002
  +;inc; pha
    lda $7f8000,x; and #$01ff; tax
    lda $7e6e00,x; and #$000f; asl #2; add $01,s; sta $01,s; plx
    lda $7e6c00,x; and #$00ff
    plx; plp; rtl
  }

  //returns the debug ID of the currently selected tile
  //I am not sure what the ID actually tells you, however
  function getTerrainDebugID {
    php; rep #$30; phx
    lda {yCoordinate}; and #$00ff; asl #6; pha
    lda {xCoordinate}; and #$003f; add $01,s
    asl; tax; pla
    lda $7f8000,x; and #$01ff; tax; sep #$20
    lda $7e7e00,x; and #$0f; asl #4; pha
    lda $7e6e00,x; and #$0f; ora $01,s; sta $01,s; pla
    plx; plp; rtl
  }

  //return a string in the form: "X:?? Y:??" (and in debug mode, "ID:??")
  function buildCoordinatesString {
    enter
    ldx #$0000; append.literal("X: ")
    lda {xCoordinate}; and #$00ff; dec #2; append.integer3()
    append.literal(" Y: ")
    lda {yCoordinate}; and #$00ff; dec #2; append.integer3()
    //if the debugger is not enabled, don't print the ID
    lda $7e1abe; and #$00ff; bne +
    leave; rtl
  +;append.literal(" ID: ")
    jsl getTerrainDebugID; append.hex02()
    leave; rtl
  }

  //return a text string identifier for the currently selected tile
  function buildTerrainTypeString {
    enter
    jsl getTerrainTypeID; ldx #$0000
    append.stringIndexed(lists.terrains.text)
    leave; rtl
  }
}

codeCursor = pc()

}
