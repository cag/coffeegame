define ['./cg'],
  (cg) ->
    {input, audio, util, game, geometry, entity, physics} = cg

    default_style =
        font: '10px sans-serif'
        lineStyles: 'white black 1.0 round round'
        fillStyle: 'rgb(26,47,158)'

    wordWrapText: (text, width, style, context) ->
        delimeter = ' '
        style = style or default_style
        context = context or game.canvas().getContext '2d'

        context.save()

        context.font = style.font
        words = text.split delimeter
        lines = []
        current_line = ''
        for word, i in words
            current_line_candidate = if i is 0 then word else current_line + delimeter + word
            if (context.measureText current_line_candidate).width > width
                lines.push current_line
                current_line = word
            else
                current_line = current_line_candidate
        lines.push current_line if current_line isnt ''

        context.restore()
        return lines

    drawTextBox: (x, y, width, height, text_obj, style, context) ->
        style = style or default_style
        context = context or game.canvas().getContext '2d'

        context.save()

        context.font = style.font
        context.textBaseline = "top"
        [
            mainLineStrokeStyle
            context.strokeStyle
            context.lineWidth
            context.lineCap
            context.lineJoin
        ] = style.lineStyles.split ' '
        context.fillStyle = style.fillStyle

        context.fillRect(x + 1.0, y + 1.0, width - 2.0, height - 2.0)
        context.strokeRect(x + 1.5, y + 1.5, width - 2.0, height - 2.0)
        context.strokeStyle = mainLineStrokeStyle
        context.strokeRect(x + 0.5, y + 0.5, width - 2.0, height - 2.0)

        context.beginPath()
        context.rect x + 2.0, y + 2.0, width - 4.0, height - 4.0
        context.clip()
        context.fillStyle = mainLineStrokeStyle
        # wordWrapText text, width - 6.0, context
        for line, i in text_obj.lines
            context.fillText line, x + 3.0, y + 3.0 + i*text_obj.spacing

        context.restore()
        return
